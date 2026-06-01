"""Kubernetes orchestration: create/destroy a student's lab slice from the same templates
the manual deploy/slice-up.sh uses. The controller is the programmatic replacement for
that script — one tenant namespace per logged-in user.
"""
import datetime
import logging
import time

from kubernetes import client, config as k8sconfig, utils
from kubernetes.client.rest import ApiException

from . import config, exercises

log = logging.getLogger("slh.k8s")

_loaded = False
_last_touch: dict[str, float] = {}


def init() -> None:
    global _loaded
    if _loaded:
        return
    try:
        k8sconfig.load_incluster_config()
        log.info("Loaded in-cluster kube config")
    except k8sconfig.ConfigException:
        k8sconfig.load_kube_config()
        log.info("Loaded local kube config")
    _loaded = True


def _api() -> client.ApiClient:
    return client.ApiClient()


def _core() -> client.CoreV1Api:
    return client.CoreV1Api()


# ---------------------------------------------------------------------------- templating

def _render(path, subs: dict[str, str]) -> str:
    text = open(path).read()
    for key, val in subs.items():
        text = text.replace("${" + key + "}", val)
    return text


def _apply(rendered: str, namespace: str) -> None:
    import yaml
    api = _api()
    for doc in yaml.safe_load_all(rendered):
        if not doc:
            continue
        try:
            utils.create_from_dict(api, doc, namespace=namespace)
        except utils.FailToCreateError as e:
            # Ignore "already exists" (409); re-raise anything else.
            for exc in e.api_exceptions:
                if exc.status != 409:
                    raise
        except ApiException as e:
            if e.status != 409:
                raise


def _subs_for(username: str, exercise: dict) -> dict[str, str]:
    ns = config.tenant_ns(username)
    subs = {
        "STUDENT_NS": ns,
        "KALI_IMAGE": config.KALI_IMAGE,
        "INGRESS_HOST": f"{ns}.lab.localhost",
        "TTYD_BASE_PATH": config.SHELL_BASE_PATH,
    }
    for placeholder, image_name in (exercise.get("manifest_images") or {}).items():
        subs[placeholder] = f"{config.REGISTRY}/{image_name}:{config.TAG}"
    return subs


# ---------------------------------------------------------------------------- lifecycle

def start_lab(username: str, exercise_id: str) -> None:
    ex = exercises.get(exercise_id)
    if not ex:
        raise ValueError(f"unknown exercise {exercise_id}")
    ns = config.tenant_ns(username)
    subs = _subs_for(username, ex)

    log.info("start_lab user=%s exercise=%s ns=%s", username, exercise_id, ns)
    # If a previous instance is still terminating, wait for it to clear so we don't try to
    # create resources in a dying namespace (the stop->start / reset race).
    try:
        existing = _core().read_namespace(ns)
        if existing.metadata.deletion_timestamp is not None:
            _wait_ns_gone(ns)
    except ApiException as e:
        if e.status != 404:
            raise
    _apply(_render(config.PLATFORM_DIR / "namespace.yaml", subs), ns)
    _annotate(ns, {
        config.ANNO_OWNER: username,
        config.ANNO_EXERCISE: exercise_id,
        config.ANNO_LAST_ACTIVITY: _now(),
    })
    _apply(_render(config.PLATFORM_DIR / "networkpolicy.yaml", subs), ns)

    # Optional init SQL -> ConfigMap named "<exercise>-initdb".
    init_sql = ex.get("init_sql")
    if init_sql:
        sql_path = ex["_dir"] / init_sql
        cm = client.V1ConfigMap(
            metadata=client.V1ObjectMeta(name=f"{exercise_id}-initdb", namespace=ns),
            data={"01-init.sql": open(sql_path).read()},
        )
        try:
            _core().create_namespaced_config_map(ns, cm)
        except ApiException as e:
            if e.status != 409:
                raise

    _apply(_render(ex["_dir"] / "manifest.yaml", subs), ns)
    _apply(_render(config.PLATFORM_DIR / "kali.yaml", subs), ns)


def stop_lab(username: str) -> None:
    ns = config.tenant_ns(username)
    log.info("stop_lab user=%s ns=%s", username, ns)
    try:
        _core().delete_namespace(ns)
    except ApiException as e:
        if e.status != 404:
            raise


def reset_lab(username: str) -> str:
    """Delete and recreate the same exercise; returns the exercise id."""
    st = status(username)
    exercise_id = st.get("exercise")
    stop_lab(username)
    _wait_ns_gone(config.tenant_ns(username))
    if exercise_id:
        start_lab(username, exercise_id)
    return exercise_id or ""


def status(username: str) -> dict:
    ns_name = config.tenant_ns(username)
    try:
        ns = _core().read_namespace(ns_name)
    except ApiException as e:
        if e.status == 404:
            return {"running": False, "namespace": ns_name}
        raise
    # A namespace mid-deletion still reads back briefly — treat it as not running.
    if ns.metadata.deletion_timestamp is not None:
        return {"running": False, "namespace": ns_name, "terminating": True}
    annos = (ns.metadata.annotations or {})
    deploys = client.AppsV1Api().list_namespaced_deployment(ns_name).items
    workloads = [{
        "name": d.metadata.name,
        "ready": (d.status.ready_replicas or 0),
        "desired": (d.spec.replicas or 0),
    } for d in deploys]
    all_ready = bool(workloads) and all(w["ready"] >= w["desired"] and w["desired"] > 0
                                        for w in workloads)
    return {
        "running": True,
        "namespace": ns_name,
        "phase": ns.status.phase,
        "exercise": annos.get(config.ANNO_EXERCISE),
        "last_activity": annos.get(config.ANNO_LAST_ACTIVITY),
        "workloads": workloads,
        "ready": all_ready,
    }


# ---------------------------------------------------------------------------- helpers

def _now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def _annotate(ns: str, annos: dict[str, str]) -> None:
    body = {"metadata": {"annotations": annos}}
    try:
        _core().patch_namespace(ns, body)
    except ApiException as e:
        if e.status != 404:
            raise


def touch_activity(username: str) -> None:
    """Throttled update of the tenant's last-activity annotation (drives idle-culling)."""
    ns = config.tenant_ns(username)
    now = time.time()
    if now - _last_touch.get(ns, 0) < 20:
        return
    _last_touch[ns] = now
    _annotate(ns, {config.ANNO_LAST_ACTIVITY: _now()})


def _wait_ns_gone(ns: str, timeout: int = 120) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            _core().read_namespace(ns)
            time.sleep(2)
        except ApiException as e:
            if e.status == 404:
                return
            raise
    raise TimeoutError(f"namespace {ns} did not terminate in {timeout}s")


def list_tenants() -> list[dict]:
    """All tenant namespaces with their last-activity (for the culler / admin view)."""
    out = []
    nss = _core().list_namespace(label_selector="slh.tenant=true").items
    for ns in nss:
        annos = ns.metadata.annotations or {}
        out.append({
            "namespace": ns.metadata.name,
            "owner": annos.get(config.ANNO_OWNER),
            "exercise": annos.get(config.ANNO_EXERCISE),
            "last_activity": annos.get(config.ANNO_LAST_ACTIVITY),
            "phase": ns.status.phase,
        })
    return out


def delete_namespace(ns: str) -> None:
    try:
        _core().delete_namespace(ns)
    except ApiException as e:
        if e.status != 404:
            raise
