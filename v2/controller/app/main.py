"""Security-Learning-Hub v2 controller — FastAPI app.

Routes: login/logout, dashboard, lab start/stop/reset, status (JSON), and the authenticated
reverse proxy for the in-browser Kali shell. A background task culls idle tenants.
"""
import asyncio
import logging

from fastapi import FastAPI, Form, Request, WebSocket
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse, Response
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware

from . import auth, config, culler, exercises, k8s, proxy

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("slh.main")

app = FastAPI(title="Security-Learning-Hub Controller")
app.add_middleware(SessionMiddleware, secret_key=config.SESSION_SECRET,
                   session_cookie="slh_session", same_site="lax")
templates = Jinja2Templates(directory=str(config.BASE_DIR / "app" / "templates"))


@app.on_event("startup")
async def _startup() -> None:
    auth.load_users()
    k8s.init()
    asyncio.create_task(culler.run_forever())
    log.info("Controller ready. Accounts: %s", auth.usernames())


def _user(request: Request) -> str | None:
    return request.session.get("user")


# --------------------------------------------------------------------------------- auth

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    if _user(request):
        return RedirectResponse("/dashboard", status_code=303)
    return RedirectResponse("/login", status_code=303)


@app.get("/login", response_class=HTMLResponse)
async def login_page(request: Request, error: str = ""):
    return templates.TemplateResponse("login.html", {"request": request, "error": error})


@app.post("/login")
async def login(request: Request, username: str = Form(...), password: str = Form(...)):
    if auth.verify(username, password):
        request.session["user"] = username
        return RedirectResponse("/dashboard", status_code=303)
    return RedirectResponse("/login?error=Invalid+credentials", status_code=303)


@app.post("/logout")
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse("/login", status_code=303)


# ---------------------------------------------------------------------------- dashboard

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    user = _user(request)
    if not user:
        return RedirectResponse("/login", status_code=303)
    st = k8s.status(user)
    return templates.TemplateResponse("dashboard.html", {
        "request": request,
        "user": user,
        "exercises": exercises.listing(),
        "status": st,
        "shell_path": config.SHELL_BASE_PATH,
    })


@app.get("/api/status")
async def api_status(request: Request):
    user = _user(request)
    if not user:
        return JSONResponse({"error": "unauthenticated"}, status_code=401)
    return JSONResponse(k8s.status(user))


@app.post("/lab/start")
async def lab_start(request: Request, exercise: str = Form(...)):
    user = _user(request)
    if not user:
        return RedirectResponse("/login", status_code=303)
    try:
        k8s.start_lab(user, exercise)
    except Exception as e:  # noqa: BLE001
        log.error("start failed: %s", e)
    return RedirectResponse("/dashboard", status_code=303)


@app.post("/lab/stop")
async def lab_stop(request: Request):
    user = _user(request)
    if not user:
        return RedirectResponse("/login", status_code=303)
    k8s.stop_lab(user)
    return RedirectResponse("/dashboard", status_code=303)


@app.post("/lab/reset")
async def lab_reset(request: Request):
    user = _user(request)
    if not user:
        return RedirectResponse("/login", status_code=303)
    try:
        k8s.reset_lab(user)
    except Exception as e:  # noqa: BLE001
        log.error("reset failed: %s", e)
    return RedirectResponse("/dashboard", status_code=303)


@app.get("/healthz")
async def healthz():
    return {"ok": True}


# -------------------------------------------------------------------------- shell proxy

@app.websocket(config.SHELL_BASE_PATH + "/ws")
async def shell_ws(ws: WebSocket):
    user = ws.session.get("user")
    if not user:
        await ws.close(code=4401)
        return
    st = k8s.status(user)
    if not st.get("running"):
        await ws.close(code=4404)
        return
    k8s.touch_activity(user)
    # ttyd base-path is SHELL_BASE_PATH, so upstream path includes it.
    await proxy.ws_proxy(ws, st["namespace"], config.SHELL_BASE_PATH.lstrip("/") + "/ws")


@app.api_route(config.SHELL_BASE_PATH, methods=["GET"])
@app.api_route(config.SHELL_BASE_PATH + "/{path:path}",
               methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"])
async def shell_http(request: Request, path: str = ""):
    user = _user(request)
    if not user:
        return RedirectResponse("/login", status_code=303)
    st = k8s.status(user)
    if not st.get("running"):
        return Response("Lab not running. Start it from the dashboard.", status_code=409)
    k8s.touch_activity(user)
    base = config.SHELL_BASE_PATH.lstrip("/")
    upstream_path = f"{base}/{path}" if path else base
    return await proxy.http_proxy(request, st["namespace"], upstream_path)
