#!/usr/bin/env bash
# Remove the controller (leaves student lab namespaces alone).
set -euo pipefail
KUBECTL="${KUBECTL:-kubectl}"
echo "[*] Deleting controller namespace slh-system + cluster RBAC..."
"$KUBECTL" delete namespace slh-system --ignore-not-found
"$KUBECTL" delete clusterrole slh-controller --ignore-not-found
"$KUBECTL" delete clusterrolebinding slh-controller --ignore-not-found
echo "[+] Controller removed."
