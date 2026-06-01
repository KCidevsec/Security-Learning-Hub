#!/usr/bin/env bash
# Register QEMU binfmt handlers so an arm64 host (Apple Silicon) can run amd64-only
# images (the vulhub CVE targets). Docker Desktop usually ships this already; this makes
# it explicit and works on plain Linux arm64 hosts too.
#
# amd64 is the canonical validation arch — this only lets the Mac *run* amd64 images under
# emulation for convenience. Always validate exercises on a native amd64 box before "done".
set -euo pipefail

echo "[*] Registering QEMU binfmt handlers (multiarch/qemu-user-static)..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

echo "[+] Registered. Quick check:"
docker run --rm --platform=linux/amd64 alpine uname -m || {
  echo "[!] amd64 emulation test failed — check Docker Desktop 'Use Rosetta' / binfmt." >&2
  exit 1
}
echo "[+] amd64 emulation works on this host."
