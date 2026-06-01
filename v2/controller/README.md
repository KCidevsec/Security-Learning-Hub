# Controller (Phase 2)

The web app that turns the lab into self-service: students log in, pick an exercise, and get
an isolated instance + an in-browser Kali shell. It's the programmatic replacement for the
manual `deploy/slice-up.sh`.

## What it does
- **Auth** — standalone accounts (pluggable; SSO later). Dev accounts via `SLH_BOOTSTRAP_USERS`;
  production via a `SLH_USERS_FILE` of bcrypt hashes.
- **Lifecycle** — `start` / `stop` / `reset` a student's lab by creating/deleting their
  namespace, rendering the same `platform/` + `exercises/` templates the scripts use.
- **Browser shell** — authenticated reverse proxy (HTTP + WebSocket) to the tenant's ttyd,
  so the terminal is reachable only through the logged-in controller, never directly.
- **Idle-culling** — a background task reaps tenants idle longer than `SLH_IDLE_TIMEOUT_MIN`,
  which is what makes ~25 students viable on one box.

## Architecture
```
browser ──HTTP/WS──> controller (slh-system ns) ──k8s API──> creates lab-<user> namespace
                          │                                   (exercise pods + Kali/ttyd)
                          └──reverse-proxy /shell ──WS──> kali-shell.lab-<user>.svc:7681
```

## Layout
- `app/` — FastAPI app: `main.py` (routes), `auth.py`, `k8s.py` (lifecycle), `proxy.py`
  (HTTP+WS shell proxy), `culler.py` (idle reaper), `exercises.py`, `config.py`, `templates/`.
- `deploy/` — `rbac.yaml` (ServiceAccount + scoped ClusterRole), `deployment.yaml`
  (Deployment+Service+Ingress), `controller-up.sh` / `controller-down.sh`.
- `Dockerfile` — build context must be `v2/` (bakes in `platform/` + `exercises/`).

## Run locally (k3d)
```bash
cd v2
make cluster-up                       # if not already up
./controller/deploy/controller-up.sh  # build, import, deploy (creates demo accounts)
kubectl port-forward -n slh-system svc/slh-controller 8000:80
open http://localhost:8000            # log in as student1 / labpass1
```

## Key env (see app/config.py)
| Var | Default | Meaning |
|-----|---------|---------|
| `SLH_BOOTSTRAP_USERS` | — | `user:pass,user2:pass2` dev accounts |
| `SLH_USERS_FILE` | — | YAML of `{user: {password_hash}}` (production) |
| `SLH_SESSION_SECRET` | dev value | session cookie signing key |
| `SLH_REGISTRY` / `SLH_TAG` | `slh` / `dev` | image refs stamped into manifests |
| `SLH_IDLE_TIMEOUT_MIN` | `60` | cull tenants idle longer than this |

## Not done yet (tracked for later phases)
- TLS + a real auth front door on the Ingress (Phase 5).
- Persistent per-student share (PVC) (Phase 4).
- Instructor/admin view across all tenants (Phase 7) — `k8s.list_tenants()` already exists.
