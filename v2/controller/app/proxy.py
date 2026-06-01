"""Reverse proxy for the in-browser shell.

ttyd in the tenant's Kali pod is served under SHELL_BASE_PATH (e.g. /shell). The controller
proxies both HTTP (page, assets, /shell/token) and the WebSocket (/shell/ws) to the tenant's
kali-shell service, so the terminal is reachable only through the authenticated controller —
never exposed directly.
"""
import asyncio
import logging

import httpx
import websockets
from fastapi import WebSocket
from starlette.background import BackgroundTask
from starlette.responses import StreamingResponse

from . import config

log = logging.getLogger("slh.proxy")

_HOP_BY_HOP = {
    "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
    "te", "trailers", "transfer-encoding", "upgrade", "host", "content-length",
}


def _upstream_host(namespace: str) -> str:
    # In-cluster service DNS for the tenant's Kali pod.
    return f"kali-shell.{namespace}.svc.cluster.local:{config.TTYD_PORT}"


async def http_proxy(request, namespace: str, path: str) -> StreamingResponse:
    url = f"http://{_upstream_host(namespace)}/{path}"
    headers = {k: v for k, v in request.headers.items() if k.lower() not in _HOP_BY_HOP}
    body = await request.body()
    client = httpx.AsyncClient(timeout=None)
    req = client.build_request(request.method, url, headers=headers,
                               params=request.query_params, content=body)
    upstream = await client.send(req, stream=True)
    resp_headers = {k: v for k, v in upstream.headers.items() if k.lower() not in _HOP_BY_HOP}
    return StreamingResponse(
        upstream.aiter_raw(),
        status_code=upstream.status_code,
        headers=resp_headers,
        background=BackgroundTask(_aclose, upstream, client),
    )


async def _aclose(upstream, client) -> None:
    await upstream.aclose()
    await client.aclose()


async def ws_proxy(ws: WebSocket, namespace: str, path: str) -> None:
    # ttyd negotiates the "tty" subprotocol; mirror whatever the browser offered.
    offered = ws.headers.get("sec-websocket-protocol", "")
    subprotocols = [p.strip() for p in offered.split(",") if p.strip()] or None
    await ws.accept(subprotocol=(subprotocols[0] if subprotocols else None))

    upstream_url = f"ws://{_upstream_host(namespace)}/{path}"
    try:
        async with websockets.connect(
            upstream_url,
            subprotocols=subprotocols or None,
            open_timeout=15,
            max_size=None,
            ping_interval=None,
        ) as upstream:
            await asyncio.gather(
                _pump_client_to_upstream(ws, upstream),
                _pump_upstream_to_client(upstream, ws),
            )
    except Exception as e:  # noqa: BLE001
        log.info("ws_proxy closed (%s): %s", namespace, e)
        try:
            await ws.close()
        except Exception:  # noqa: BLE001
            pass


async def _pump_client_to_upstream(ws: WebSocket, upstream) -> None:
    try:
        while True:
            msg = await ws.receive()
            if msg["type"] == "websocket.disconnect":
                await upstream.close()
                return
            if msg.get("text") is not None:
                await upstream.send(msg["text"])
            elif msg.get("bytes") is not None:
                await upstream.send(msg["bytes"])
    except Exception:  # noqa: BLE001
        await upstream.close()


async def _pump_upstream_to_client(upstream, ws: WebSocket) -> None:
    try:
        async for message in upstream:
            if isinstance(message, (bytes, bytearray)):
                await ws.send_bytes(message)
            else:
                await ws.send_text(message)
    except Exception:  # noqa: BLE001
        pass
