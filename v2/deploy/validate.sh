#!/usr/bin/env bash
# Render every template with sample values and confirm the output is well-formed YAML.
# Pure client-side — needs no cluster. Full k8s schema checks happen at `kubectl apply`.
set -euo pipefail

V2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STUDENT_NS="lab-student-01"
KALI_IMAGE="slh/kali-ttyd:dev"
IMAGE_WEB="slh/sqli-demo-web:dev"
INGRESS_HOST="lab-student-01.lab.localhost"

render() {
  sed -e "s|\${STUDENT_NS}|${STUDENT_NS}|g" \
      -e "s|\${KALI_IMAGE}|${KALI_IMAGE}|g" \
      -e "s|\${IMAGE_WEB}|${IMAGE_WEB}|g" \
      -e "s|\${INGRESS_HOST}|${INGRESS_HOST}|g" \
      -e "s|\${TTYD_BASE_PATH}|${TTYD_BASE_PATH:-}|g" \
      "$1"
}

# Pick an available YAML parser: pyyaml if present, else Ruby (ships on macOS).
if python3 -c 'import yaml' >/dev/null 2>&1; then
  YAML_CHECK=(python3 -c 'import sys,yaml; list(yaml.safe_load_all(sys.stdin))')
elif command -v ruby >/dev/null 2>&1; then
  YAML_CHECK=(ruby -ryaml -e 'YAML.load_stream(STDIN.read)')
else
  echo "[!] Need python3+pyyaml or ruby to validate YAML." >&2; exit 1
fi

check() {
  local f="$1"
  printf '  %-48s ' "$(basename "$(dirname "$f")")/$(basename "$f")"
  if render "$f" | "${YAML_CHECK[@]}" 2>/dev/null; then
    echo "OK"
  else
    echo "INVALID YAML"; render "$f" | "${YAML_CHECK[@]}"; exit 1
  fi
}

echo "[*] Validating rendered manifests..."
check "${V2_DIR}/platform/namespace.yaml"
check "${V2_DIR}/platform/networkpolicy.yaml"
check "${V2_DIR}/platform/kali.yaml"
check "${V2_DIR}/exercises/sqli-demo/manifest.yaml"
echo "[+] All manifests render to valid YAML."
