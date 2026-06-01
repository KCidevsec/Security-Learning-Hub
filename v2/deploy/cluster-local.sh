#!/usr/bin/env bash
# Stand up a local k3s cluster (via k3d) for development on the Mac.
# k3d runs k3s inside Docker, so dev matches the mini-PC/cloud runtime (same k3s API).
set -euo pipefail
KUBECTL="${KUBECTL:-kubectl}"

CLUSTER="${SLH_CLUSTER:-slh-dev}"

if ! command -v k3d >/dev/null 2>&1; then
  echo "[*] k3d not found — installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install k3d
  else
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  fi
fi

if k3d cluster list 2>/dev/null | awk '{print $1}' | grep -qx "${CLUSTER}"; then
  echo "[=] Cluster '${CLUSTER}' already exists."
else
  echo "[*] Creating k3d cluster '${CLUSTER}' (Traefik ingress on :8080, :8443)..."
  # Map host 8080->ingress so real Ingress works locally; port-forward is the simpler path.
  k3d cluster create "${CLUSTER}" \
    -p "8080:80@loadbalancer" \
    -p "8443:443@loadbalancer" \
    --agents 1
fi

"$KUBECTL" config use-context "k3d-${CLUSTER}" >/dev/null 2>&1 || true
echo "[+] Cluster ready. Context: k3d-${CLUSTER}"
"$KUBECTL" get nodes -o wide
