"""Idle culler: periodically reap tenant namespaces whose last-activity exceeds the idle
timeout. This is what makes ~25 students viable on one box — inactive labs free their RAM.
"""
import asyncio
import datetime
import logging

from . import config, k8s

log = logging.getLogger("slh.culler")


def _age_minutes(iso_ts: str | None) -> float | None:
    if not iso_ts:
        return None
    try:
        ts = datetime.datetime.fromisoformat(iso_ts)
        now = datetime.datetime.now(datetime.timezone.utc)
        return (now - ts).total_seconds() / 60.0
    except Exception:  # noqa: BLE001
        return None


async def run_forever() -> None:
    log.info("Culler started: idle timeout %d min, interval %ds",
             config.IDLE_TIMEOUT_MIN, config.CULL_INTERVAL_SEC)
    while True:
        try:
            cull_once()
        except Exception as e:  # noqa: BLE001
            log.error("cull pass failed: %s", e)
        await asyncio.sleep(config.CULL_INTERVAL_SEC)


def cull_once() -> int:
    reaped = 0
    for tenant in k8s.list_tenants():
        age = _age_minutes(tenant.get("last_activity"))
        if age is not None and age >= config.IDLE_TIMEOUT_MIN:
            log.info("Culling %s (idle %.1f min, owner=%s)",
                     tenant["namespace"], age, tenant.get("owner"))
            k8s.delete_namespace(tenant["namespace"])
            reaped += 1
    return reaped
