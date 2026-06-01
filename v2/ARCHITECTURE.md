# v2 Architecture

## Goal

Each of ~25 students per semester gets an **isolated, browser-accessible lab instance**.
They log in to a web app, start an exercise, and get a terminal into a Kali attacker box —
all in the browser, with nothing installed locally and no full-lab build.

## High-level shape

```
                     ┌─────────────────────────────────────┐
   Student browser → │  Ingress / reverse proxy (+ auth)    │
                     └─────────────────────────────────────┘
                                     │
                     ┌─────────────────────────────────────┐
                     │  Controller web app (Phase 2)        │  accounts, start/stop/reset,
                     │  (talks to the Kubernetes API)       │  idle-culling
                     └─────────────────────────────────────┘
                                     │ creates a namespace per student
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
  ns: lab-student-01          ns: lab-student-02          ns: lab-student-NN
  ┌────────────────────┐      ┌────────────────────┐
  │ kali + ttyd  (pod) │◄──── │ kali + ttyd  (pod) │   NetworkPolicy:
  │ exercise target(s) │ shell│ exercise target(s) │   default-deny cross-namespace,
  └────────────────────┘      └────────────────────┘   allow intra-namespace
```

## Key decisions and why

### Orchestration: k3s (not full k8s, not bare Docker)
- The deploy target is a **single Intel mini PC**; full k8s is overkill, bare Docker
  gives weak isolation.
- **k3s** is lightweight enough for one box but speaks the **same API** as full Kubernetes,
  so the *exact same manifests* deploy to **AWS EKS** later with zero rewrite. Cloud becomes
  a scaling lever, not a fork.
- Local dev on the Mac uses **k3d** (k3s-in-Docker) so dev and prod are the same runtime.

### Tenancy: namespace per student + NetworkPolicy
- One **namespace per student** (`lab-student-<id>`) is the isolation unit: easy to create,
  quota, and tear down/reset wholesale.
- A **default-deny** `NetworkPolicy` blocks cross-namespace traffic so student A cannot
  scan/pivot into student B's targets, and a compromised target cannot reach other tenants.
  Intra-namespace traffic is allowed (Kali ↔ its own targets). Ingress-controller traffic to
  the ttyd port is explicitly allowed so the browser shell works.
- k3s ships a NetworkPolicy controller; for stronger guarantees swap in Calico/Cilium.

### Browser shell: ttyd sidecar
- **ttyd** wraps `bash` and serves it over a websocket — the same Kali CLI experience
  students have today, in a browser tab. Lightest option; GUI (Guacamole/VNC) is a
  deferred, per-exercise add-on.
- Runs as a container in the Kali pod, exposed via Ingress (real) or `kubectl port-forward`
  (the dead-simple fallback used for local validation).

### Resource model: on-demand, per-exercise (NOT all stacks at once)
- v1 runs ~23 stacks simultaneously. v2 spins up **only the active exercise's targets +
  Kali** (~2–4 containers/student), and **idle-culls** the rest.
- This is what makes 25 students viable on one box. RAM is the binding constraint:
  ~1.5–3 GB per active student. A 32 GB mini PC comfortably serves ~10–12 concurrent;
  all-25-at-once is the documented trigger for an AWS burst.

### Architecture portability: multi-arch images, amd64 canonical
- Dev box is **Apple Silicon (arm64)**; deploy box is **Intel (amd64)**. v1 handles this with
  two directory trees + `uname -p` branching.
- v2 builds **multi-arch images** (`docker buildx --platform linux/amd64,linux/arm64 --push`)
  into **GHCR**. One Dockerfile per image; k8s pulls the right arch per node. The dual tree
  collapses.
- **vulhub CVE images are mostly amd64-only** and will never be arm64-native — on Apple
  Silicon they run under **QEMU emulation** (slower; a few timing-sensitive exploits may
  differ). Therefore **amd64 is the source of truth**: an exercise is only "done" once
  verified on amd64 (mini PC or an amd64 CI runner). Per-exercise arch status lives in
  `docs/arch-compat-matrix.md`.

### Auth: standalone now, pluggable later
- v1 of the controller uses a standalone account list. Auth is kept as a thin, replaceable
  layer so university SSO (SAML/OAuth/LDAP) can slot in if this goes institution-wide.

## Security posture (non-negotiable)
This platform hosts deliberately-vulnerable, sometimes-privileged workloads for 25 students.
It must **never** be exposed raw to the internet — it sits behind authentication and/or a
VPN. Cross-tenant isolation is enforced by NetworkPolicy, namespace boundaries, and resource
quotas. Privileged exercises are flagged and constrained where the exploit permits.

## What's built so far (Phase 0/1 vertical slice)
- `images/kali-ttyd` — attacker box with ttyd browser shell.
- `exercises/sqli-demo` — the SQLi exercise ported to k8s (faithful to the original
  SQLi → `INTO OUTFILE` → webshell chain).
- `platform/` — per-student namespace + NetworkPolicy + Kali pod/service/ingress templates.
- `deploy/` — local cluster bring-up, multi-arch build/push, binfmt setup, slice up/down.

## Not built yet
- The controller web app (Phase 2): accounts, start/stop/reset UI, idle-culling.
- Remaining exercise ports (Phase 3).
- Production Ingress + TLS + auth front door.
