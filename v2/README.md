# Security-Learning-Hub — v2 (web lab platform)

> **Status: in development on `feature/web-lab-platform`. Not for student use yet.**
> The live lab students currently use is the v1 `main.sh` system at the repo root.
> Nothing in this folder affects v1 — v2 is fully self-contained under `v2/`.

v2 turns the Hub into a **multi-tenant, browser-accessible cyber range**: each student
logs in, gets an **isolated lab instance** (their own Kubernetes namespace), picks an
exercise, and gets a **browser shell** into a Kali attacker box — no local build, no
Docker on their laptop.

## Why v2 exists

The v1 lab is excellent but has friction:

- Students must `git pull` and **build the entire lab locally** on first run (slow).
- It runs **all ~23 vulnerable stacks at once** — heavy, and everything is on one machine.
- It carries **two parallel image trees** (`docker_files/` for arm64, `docker_files_x86_64/`
  for amd64) and branches on `uname -p`.

v2 fixes all three: pre-built images pulled from a registry, **per-exercise on-demand**
spin-up, and **multi-arch images** so the dual tree collapses to one.

## Design at a glance

| Concern            | v2 choice                                                                 |
|--------------------|---------------------------------------------------------------------------|
| Orchestration      | **k3s** (single-node on the Intel mini PC) → same manifests scale to AWS EKS |
| Tenancy / isolation| **Namespace per student** + default-deny cross-namespace `NetworkPolicy`  |
| Browser access     | **ttyd** sidecar in the Kali pod → authenticated Ingress / port-forward   |
| Auth               | Standalone accounts for v1 (pluggable; SSO later)                         |
| Images             | **Multi-arch** (`buildx` → GHCR); **amd64 is the canonical validation arch** |
| GUI                | Terminal-only (GUI desktop is a later, per-exercise option)               |

See [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the full design and rationale.

## Layout

```
v2/
├── README.md                 # this file
├── ARCHITECTURE.md           # design + rationale + scaling path
├── MORNING-REPORT.md         # what was built unattended + what needs your input
├── Makefile                  # cluster-up, build, slice-up, slice-down, validate
├── images/
│   └── kali-ttyd/            # attacker box + ttyd browser shell (multi-arch)
├── exercises/
│   ├── sqli-demo/            # SQLi exercise (k8s manifests + images + src)
│   └── ftp-anon/             # anonymous-FTP exercise (multi-arch vsftpd)
├── platform/                 # per-student namespace + NetworkPolicy + Kali pod templates
├── controller/               # Phase 2 web app: login, lifecycle, shell proxy, culler
│   ├── app/                  # FastAPI (main, auth, k8s, proxy, culler, exercises)
│   └── deploy/               # RBAC, Deployment/Service/Ingress, up/down scripts
├── deploy/                   # cluster bring-up, multi-arch build/push, binfmt, slice scripts
└── docs/
    └── arch-compat-matrix.md # which exercises are native-both vs amd64-only (emulated)
```

## Two ways to run

**Self-service via the controller (Phase 2 — the real UX):**
```bash
cd v2
make cluster-up
make build                              # build + import all images into the cluster
./controller/deploy/controller-up.sh    # deploy controller (demo accounts student1/2)
open http://localhost:8080              # log in -> pick an exercise -> in-browser Kali shell
```
(k3d publishes Traefik on `localhost:8080`; the controller Ingress has no host match, so
`http://localhost:8080` routes straight to it. `kubectl port-forward -n slh-system
svc/slh-controller 8000:80` is an alternative.)

**Manual single slice (Phase 1 — scripted, no controller):**
```bash
cd v2
make cluster-up        # local k3d cluster (installs k3d if missing)
make slice-up          # deploy the SQLi exercise + Kali/ttyd into namespace lab-student-01
make shell             # port-forward the browser shell -> http://localhost:7681
make slice-down        # tear the student namespace down
```

> On Apple Silicon, amd64-only exercises run under QEMU emulation (slower). The mini PC
> and cloud run them natively. **amd64 is the source of truth** — an exercise isn't "done"
> until it passes on amd64. See `docs/arch-compat-matrix.md`.

## Phased plan

- **Phase 0** — registry-backed multi-arch images. *Build path verified for both arches;
  actual GHCR push needs your `docker login` (see MORNING-REPORT.md).*
- **Phase 1** — vertical slice: SQLi + Kali/ttyd, one student namespace, in-browser. ✅ **done & verified**
- **Phase 2** — controller web app: login, start/stop/reset, shell proxy, idle-culling. ✅ **done & verified**
- **Phase 3** — port remaining exercises (ftp-anon done ✅); load-test concurrency; AWS cost case. *in progress*
- **Phase 4+** — persistence (PVC), security front-door/TLS, scale to EKS, instructor tools.
  See ARCHITECTURE.md / MORNING-REPORT.md.
