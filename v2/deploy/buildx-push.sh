#!/usr/bin/env bash
# Build the v2 custom images as MULTI-ARCH (amd64 + arm64) and push to a registry (GHCR).
# This is the Phase-0 win: students/nodes PULL prebuilt images instead of building locally,
# and one tag serves both architectures (collapsing the v1 dual-tree).
#
# Usage:
#   REGISTRY=ghcr.io/<owner> TAG=0.1.0 ./deploy/buildx-push.sh
# Prereqs: `docker login ghcr.io`, and a buildx builder (created here if missing).
set -euo pipefail

V2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${REGISTRY:?set REGISTRY, e.g. ghcr.io/yourname}"
TAG="${TAG:-dev}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

if ! docker buildx inspect slh-builder >/dev/null 2>&1; then
  echo "[*] Creating buildx builder 'slh-builder'..."
  docker buildx create --name slh-builder --use --bootstrap
else
  docker buildx use slh-builder
fi

build() {
  local image="$1" ctx="$2" dockerfile="$3"
  echo "[*] Building ${REGISTRY}/${image}:${TAG} for ${PLATFORMS}..."
  docker buildx build \
    --platform "${PLATFORMS}" \
    -t "${REGISTRY}/${image}:${TAG}" \
    -f "${dockerfile}" \
    --push \
    "${ctx}"
}

build "kali-ttyd"     "${V2_DIR}/images/kali-ttyd"        "${V2_DIR}/images/kali-ttyd/Dockerfile"
build "sqli-demo-web" "${V2_DIR}/exercises/sqli-demo"     "${V2_DIR}/exercises/sqli-demo/images/web/Dockerfile"

echo "[+] Pushed multi-arch images to ${REGISTRY} (tag ${TAG})."
