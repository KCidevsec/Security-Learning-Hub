# Morning report — overnight work (2026-06-01 → 02)

Worked unattended on `feature/web-lab-platform`. **`main` was never touched.** Everything is
under `v2/`, committed in reviewable chunks. The local k3d cluster is **left running** so you
can see it live (see "Try it" below).

## TL;DR
Phases 1 and 2 are **done and verified end-to-end on a real cluster**, Phase 3 has its first
exercise ported, and the platform is hardened with egress isolation. The only thing I could
not do (needs your credentials) is the actual GHCR image push.

## What I did, with proof

### ✅ Phase 5 (partial) — egress isolation
Added default-deny egress per tenant (allow only intra-namespace + DNS). Re-verified: SQLi
exploit chain + DNS still work; **internet egress and cross-tenant access now both blocked**
(HTTP 000). Commit `10827ac`.

### ✅ Phase 0 — multi-arch build verification
`docker buildx --platform linux/amd64,linux/arm64` builds clean for **both** images
(kali-ttyd's amd64 built under QEMU emulation here). Manifests are registry-agnostic
(`${REGISTRY}/...`). **Left for you:** `docker login ghcr.io` then `REGISTRY=ghcr.io/<you>
TAG=x make push` — I can't authenticate as you.

### ✅ Phase 2 — controller web app (the big one)
A FastAPI controller (`v2/controller/`) that makes the lab self-service. Verified on k3d,
**every step tested**:
1. login (session cookie) ✅
2. start a lab → creates the student's namespace + isolation policy + exercise + Kali ✅
3. lab reaches ready (both workloads) ✅
4. browser shell over the authenticated HTTP proxy (ttyd page loads) ✅
5. **interactive shell over the proxied WebSocket** — typed a command, got output back ✅
6. stop / two-student namespace isolation ✅
7. **idle-culling** — 0 reaped when fresh; reaps a tenant backdated past the timeout ✅
Commits `297918a`, `f6934c5`, `12e4b57`.

### ✅ Phase 3 (started) — second exercise: ftp-anon
Ported the anonymous-FTP exercise, rebuilt on `ubuntu:22.04` so it's **multi-arch** (the v1
phusion image was amd64-only). Verified through the controller: catalogue auto-lists it,
student starts it, and from the Kali shell — nmap finds vsftpd, anonymous login lists files,
**flag captured** (`FLAG{anonymous_ftp_exposed}`), credentials dumped. Commit `12e4b57`.

## Bugs I found and fixed while testing (not just happy-path)
- **Shell proxy dropped the trailing slash** → ttyd 302-looped `/shell`→`/shell/`. Fixed by
  proxying the real request path. The browser terminal now loads + the WS round-trips.
- **MySQL→Apache webshell perms** (the same wrinkle v1 hit): OUTFILE files were `0640 mysql`,
  unreadable by `www-data`. Fixed with `umask 0002` on MySQL + adding www-data to gid 999.
- **FTP passive mode in k8s**: ClusterIP service doesn't carry passive ports. Switched to a
  **headless service** so the name resolves to the pod IP where the passive ports live.
- **stop→start / reset race**: `start_lab` now waits for a terminating namespace to clear
  before recreating.

## Decisions I made (so I didn't have to wake you)
- **k3d kubectl workaround**: your PATH `kubectl` is Rancher Desktop's `kuberlr` shim and is
  **broken** (fetches wrong-arch binary, 404s). I used Docker Desktop's real kubectl at
  `/usr/local/bin/kubectl`; scripts now accept a `KUBECTL=` override. Worth fixing your PATH.
- **Demo accounts**: `student1/labpass1`, `student2/labpass2` (dev bootstrap; production path
  uses bcrypt-hashed `SLH_USERS_FILE`).
- **ftp-anon as native multi-arch** rather than chasing a genuinely amd64-only vulhub port
  overnight — kept momentum. A real amd64-only/emulation port is still a Phase 3 to-do.
- **Idle timeout** defaulted to 60 min.

## What needs YOU
1. **GHCR push** — `docker login ghcr.io`, then `REGISTRY=ghcr.io/<you> TAG=0.1.0 make push`
   (and the same REGISTRY when deploying) to complete Phase 0.
2. **Fix the kubectl shim** in your shell PATH (or keep using the `KUBECTL=` override).
3. **Decisions for next phases**: real auth front-door (Phase 5) — SSO vs basic-auth + TLS;
   persistence (Phase 4) — per-student PVC size; how many vulhub exercises to prioritise for
   Phase 3, and whether to do the first amd64-only/emulation port next.

## Try it (cluster is still up)
```bash
cd v2
/usr/local/bin/kubectl port-forward -n slh-system svc/slh-controller 8000:80
open http://localhost:8000          # log in as student1 / labpass1 -> Start an exercise
```
Tear everything down: `make cluster-down` (deletes the whole k3d cluster).

## Honest status / caveats
- All verification was on **arm64 k3d** (your Mac). Per our rule, **amd64 is canonical** —
  these still need a pass on the Intel mini PC before they're "done" for students.
- This is a **dev/pilot** build: the controller has no TLS/front-door yet (Phase 5), the
  Kali share is `emptyDir` (no persistence yet, Phase 4), and accounts are dev bootstrap.
- Not load-tested for 25 concurrent yet (Phase 6) — that's the data for the AWS case.
