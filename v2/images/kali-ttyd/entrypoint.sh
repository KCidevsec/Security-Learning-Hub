#!/usr/bin/env bash
# Entrypoint for the Kali + ttyd attacker box.
#
# Serves an interactive login shell over a websocket on :7681 so students get the same
# Kali CLI experience as the v1 lab, but in a browser tab.
#
# Optional env:
#   TTYD_CREDENTIAL   "user:pass" for ttyd basic-auth (defence in depth behind the
#                     ingress auth layer). Unset = no ttyd-level auth.
#   TTYD_PORT         listen port (default 7681)
#   WELCOME_MSG       text shown when the shell opens
set -euo pipefail

TTYD_PORT="${TTYD_PORT:-7681}"
WELCOME_MSG="${WELCOME_MSG:-Welcome to your Security-Learning-Hub lab shell (Kali). Targets are reachable by service name within your lab.}"

# Drop a per-session MOTD so students know where they are.
cat > /root/.lab_motd <<EOF
============================================================
  ${WELCOME_MSG}
  Try:  nmap -sV <target-service>      sqlmap -u <url>
  Your persistent share: /root/kali_share_folder
============================================================
EOF
grep -q lab_motd /root/.bashrc 2>/dev/null || echo 'cat /root/.lab_motd' >> /root/.bashrc

TTYD_ARGS=(--writable --port "${TTYD_PORT}" --terminal-type xterm-256color)
if [[ -n "${TTYD_CREDENTIAL:-}" ]]; then
    TTYD_ARGS+=(--credential "${TTYD_CREDENTIAL}")
fi
# When served behind the controller's reverse proxy under a sub-path (e.g. /shell), ttyd
# must emit asset/token/ws URLs under that base path. Left empty for direct/port-forward.
if [[ -n "${TTYD_BASE_PATH:-}" ]]; then
    TTYD_ARGS+=(--base-path "${TTYD_BASE_PATH}")
fi

exec ttyd "${TTYD_ARGS[@]}" bash -l
