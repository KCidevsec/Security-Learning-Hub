#!/usr/bin/env bash
# Build the v2 images for LOCAL k3d use (single-arch = the Mac's native arch) and import
# them into the k3d cluster so manifests can reference them without a registry.
# For multi-arch registry builds use deploy/buildx-push.sh instead.
set -euo pipefail

V2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER="${SLH_CLUSTER:-slh-dev}"
REGISTRY="${REGISTRY:-slh}"
TAG="${TAG:-dev}"

KALI_IMAGE="${REGISTRY}/kali-ttyd:${TAG}"
IMAGE_WEB="${REGISTRY}/sqli-demo-web:${TAG}"

echo "[*] Building ${KALI_IMAGE}..."
docker build -t "${KALI_IMAGE}" \
  -f "${V2_DIR}/images/kali-ttyd/Dockerfile" \
  "${V2_DIR}/images/kali-ttyd"

echo "[*] Building ${IMAGE_WEB}..."
docker build -t "${IMAGE_WEB}" \
  -f "${V2_DIR}/exercises/sqli-demo/images/web/Dockerfile" \
  "${V2_DIR}/exercises/sqli-demo"

echo "[*] Importing images into k3d cluster '${CLUSTER}'..."
k3d image import "${KALI_IMAGE}" "${IMAGE_WEB}" -c "${CLUSTER}"

echo "[+] Local images built and imported."
