#!/usr/bin/env bash
# Bring up ONE student's lab slice: namespace + isolation policy + the SQLi exercise +
# the Kali/ttyd shell. This is the Phase-1 vertical slice; Phase 2 replaces it with a
# controller that calls the k8s API per logged-in student.
#
# Usage: ./deploy/slice-up.sh [student-ns]   (default: lab-student-01)
set -euo pipefail
KUBECTL="${KUBECTL:-kubectl}"

V2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STUDENT_NS="${1:-lab-student-01}"
REGISTRY="${REGISTRY:-slh}"
TAG="${TAG:-dev}"
KALI_IMAGE="${REGISTRY}/kali-ttyd:${TAG}"
IMAGE_WEB="${REGISTRY}/sqli-demo-web:${TAG}"
INGRESS_HOST="${INGRESS_HOST:-${STUDENT_NS}.lab.localhost}"

# Substitute ${...} placeholders in a template. '|' delimiter avoids clashing with '/' in
# image names. Avoids depending on envsubst (not always present on macOS).
render() {
  sed -e "s|\${STUDENT_NS}|${STUDENT_NS}|g" \
      -e "s|\${KALI_IMAGE}|${KALI_IMAGE}|g" \
      -e "s|\${IMAGE_WEB}|${IMAGE_WEB}|g" \
      -e "s|\${INGRESS_HOST}|${INGRESS_HOST}|g" \
      -e "s|\${TTYD_BASE_PATH}|${TTYD_BASE_PATH:-}|g" \
      "$1"
}

echo "[*] Slice: ${STUDENT_NS}  (web=${IMAGE_WEB}, kali=${KALI_IMAGE})"

echo "[*] Namespace + quota..."
render "${V2_DIR}/platform/namespace.yaml" | "$KUBECTL" apply -f -

echo "[*] Network isolation policy..."
render "${V2_DIR}/platform/networkpolicy.yaml" | "$KUBECTL" apply -f -

echo "[*] Exercise init SQL (ConfigMap)..."
"$KUBECTL" create configmap sqli-demo-initdb \
  --from-file=01-init.sql="${V2_DIR}/exercises/sqli-demo/init.sql" \
  -n "${STUDENT_NS}" \
  --dry-run=client -o yaml | "$KUBECTL" apply -f -

echo "[*] SQLi exercise workload..."
render "${V2_DIR}/exercises/sqli-demo/manifest.yaml" | "$KUBECTL" apply -n "${STUDENT_NS}" -f -

echo "[*] Kali + ttyd shell..."
render "${V2_DIR}/platform/kali.yaml" | "$KUBECTL" apply -f -

echo "[*] Waiting for rollouts..."
"$KUBECTL" rollout status deploy/sqli-demo -n "${STUDENT_NS}" --timeout=180s
"$KUBECTL" rollout status deploy/kali       -n "${STUDENT_NS}" --timeout=180s

cat <<EOF

[+] Slice '${STUDENT_NS}' is up.

    Browser shell (simplest, bypasses ingress):
      "$KUBECTL" port-forward -n ${STUDENT_NS} svc/kali-shell 7681:7681
      open http://localhost:7681          # or: make shell

    From the Kali shell, attack the target:
      curl http://sqli-web/
      sqlmap -u 'http://sqli-web/' --data 'user_id=1' --batch

    Tear down:  ./deploy/slice-down.sh ${STUDENT_NS}
EOF
