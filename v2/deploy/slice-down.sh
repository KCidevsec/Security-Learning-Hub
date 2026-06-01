#!/usr/bin/env bash
# Tear down one student's lab slice by deleting the namespace (removes the exercise, the
# Kali pod, any uploaded webshells, and the isolation policies in one shot).
#
# Usage: ./deploy/slice-down.sh [student-ns]   (default: lab-student-01)
set -euo pipefail
KUBECTL="${KUBECTL:-kubectl}"
STUDENT_NS="${1:-lab-student-01}"
echo "[*] Deleting namespace ${STUDENT_NS}..."
"$KUBECTL" delete namespace "${STUDENT_NS}" --ignore-not-found
echo "[+] Slice '${STUDENT_NS}' removed."
