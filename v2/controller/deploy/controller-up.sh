#!/usr/bin/env bash
# Build, import, and deploy the controller into the local k3d cluster.
# Usage: [BOOTSTRAP_USERS=u:p,...] ./controller/deploy/controller-up.sh
set -euo pipefail
KUBECTL="${KUBECTL:-kubectl}"

V2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER="${SLH_CLUSTER:-slh-dev}"
CONTROLLER_IMAGE="${CONTROLLER_IMAGE:-slh/controller:dev}"
SLH_REGISTRY="${SLH_REGISTRY:-slh}"
SLH_TAG="${SLH_TAG:-dev}"
SLH_IDLE_TIMEOUT_MIN="${SLH_IDLE_TIMEOUT_MIN:-60}"
CONTROLLER_HOST="${CONTROLLER_HOST:-hub.localhost}"
BOOTSTRAP_USERS="${BOOTSTRAP_USERS:-student1:labpass1,student2:labpass2}"

echo "[*] Building ${CONTROLLER_IMAGE} (context=${V2_DIR})..."
docker build -t "${CONTROLLER_IMAGE}" -f "${V2_DIR}/controller/Dockerfile" "${V2_DIR}"

echo "[*] Importing image into k3d cluster '${CLUSTER}'..."
k3d image import "${CONTROLLER_IMAGE}" -c "${CLUSTER}"

echo "[*] RBAC + namespace..."
"$KUBECTL" apply -f "${V2_DIR}/controller/deploy/rbac.yaml"

echo "[*] Secret (session key + bootstrap accounts)..."
SESSION_SECRET="$(openssl rand -hex 32 2>/dev/null || echo dev-insecure-change-me)"
"$KUBECTL" create secret generic slh-controller -n slh-system \
  --from-literal=session-secret="${SESSION_SECRET}" \
  --from-literal=bootstrap-users="${BOOTSTRAP_USERS}" \
  --dry-run=client -o yaml | "$KUBECTL" apply -f -

echo "[*] Deploying controller..."
sed -e "s|\${CONTROLLER_IMAGE}|${CONTROLLER_IMAGE}|g" \
    -e "s|\${SLH_REGISTRY}|${SLH_REGISTRY}|g" \
    -e "s|\${SLH_TAG}|${SLH_TAG}|g" \
    -e "s|\${SLH_IDLE_TIMEOUT_MIN}|${SLH_IDLE_TIMEOUT_MIN}|g" \
    -e "s|\${CONTROLLER_HOST}|${CONTROLLER_HOST}|g" \
    "${V2_DIR}/controller/deploy/deployment.yaml" | "$KUBECTL" apply -f -

"$KUBECTL" rollout status deploy/slh-controller -n slh-system --timeout=120s

cat <<EOF

[+] Controller deployed.
    Accounts: ${BOOTSTRAP_USERS}
    Access it:
      "$KUBECTL" port-forward -n slh-system svc/slh-controller 8000:80
      open http://localhost:8000
EOF
