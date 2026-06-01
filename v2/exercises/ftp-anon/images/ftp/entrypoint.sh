#!/bin/bash
# Passive FTP in a pod needs vsftpd to advertise an IP the client can reach. Within the
# namespace, the pod IP is routable from Kali, so advertise that.
set -e
POD_IP="$(hostname -i | awk '{print $1}')"
echo "pasv_address=${POD_IP}" >> /etc/vsftpd.conf
echo "[ftp-anon] starting vsftpd, pasv_address=${POD_IP}"
exec /usr/sbin/vsftpd /etc/vsftpd.conf
