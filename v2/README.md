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
├── Makefile                  # cluster-up, build, slice-up, slice-down, validate
├── images/
│   └── kali-ttyd/            # attacker box + ttyd browser shell (multi-arch)
├── exercises/
│   └── sqli-demo/            # first ported exercise (k8s manifests + images + src)
├── platform/                 # per-student namespace + NetworkPolicy + Kali pod templates
├── deploy/                   # cluster bring-up, multi-arch build/push, binfmt, slice scripts
└── docs/
    └── arch-compat-matrix.md # which exercises are native-both vs amd64-only (emulated)
```

## Quick start (local dev on Apple Silicon)

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

- **Phase 0** — registry-backed multi-arch images (kills the local build pain). *in progress*
- **Phase 1** — vertical slice: one exercise (SQLi) + Kali/ttyd, one student namespace, in-browser. *in progress*
- **Phase 2** — controller web app (login, start/stop/reset, idle-culling) + multi-tenancy.
- **Phase 3** — port remaining exercises; load-test concurrency; cost case for AWS.
