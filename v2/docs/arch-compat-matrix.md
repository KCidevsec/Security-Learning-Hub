# Architecture compatibility matrix

Dev is on **Apple Silicon (arm64)**; the mini PC and cloud are **amd64**. **amd64 is the
canonical validation arch** — an exercise is "done" only once it passes on amd64.

Legend:
- **native** — an arm64-native image exists; runs without emulation on both arches.
- **amd64-only (emulated on arm64)** — no arm64 build; runs natively on amd64, under QEMU on
  Apple Silicon (slower; a few timing-sensitive exploits may behave differently).

| Exercise / image        | amd64  | arm64                      | Notes                                  |
|-------------------------|--------|----------------------------|----------------------------------------|
| kali-ttyd               | native | native                     | Kali + ttyd both multi-arch (verified) |
| sqli-demo (web)         | native | native                     | php:8.1-apache is multi-arch (verified)|
| sqli-demo (db)          | native | native                     | mysql:8.0 is multi-arch                |
| ftp-anon                | native | native                     | rebuilt on ubuntu:22.04 (was phusion amd64-only) |
| _vulhub CVE stacks_     | native | mostly amd64-only (emulated) | ported in Phase 3; flag each as ported |

> "verified" = `docker buildx --platform linux/amd64,linux/arm64` builds clean for both
> arches (kali-ttyd's amd64 built under QEMU emulation on the Apple Silicon dev box).
> A genuinely amd64-only port (the emulation path) is still pending in Phase 3.

## How this is enforced
- Custom images are built multi-arch (`make push`, `deploy/buildx-push.sh`).
- On arm64 hosts, `make binfmt` registers QEMU so amd64-only images still run.
- `meta.yaml` per exercise records `arch:` + `emulated_on_apple_silicon:`; the Phase-2
  controller surfaces a "runs under emulation on Apple Silicon" note to students.

## Why amd64 is canonical
The mini PC is amd64, cloud will be amd64, and vulhub images are predominantly amd64-only.
Choosing amd64 maximises the number of exercises that run **natively and correctly**, and
prevents "worked on my Mac, broke in the lab" emulation-divergence surprises.
