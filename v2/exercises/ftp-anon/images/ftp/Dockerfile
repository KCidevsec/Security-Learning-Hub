# Anonymous-FTP exposure exercise. Multi-arch (ubuntu:22.04 publishes amd64 + arm64), so
# unlike the v1 phusion/baseimage build this runs natively on Apple Silicon too.
FROM ubuntu:22.04

LABEL org.opencontainers.image.title="ftp-anon"
LABEL org.opencontainers.image.description="Misconfigured anonymous FTP server (Security-Learning-Hub v2)"
LABEL warning="Intentionally misconfigured. Educational use only."

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends vsftpd \
    && rm -rf /var/lib/apt/lists/*

# Anonymous FTP root + planted loot.
RUN mkdir -p /srv/ftp /var/run/vsftpd/empty
COPY loot/ /srv/ftp/
RUN chmod -R a+rX /srv/ftp

COPY images/ftp/vsftpd.conf /etc/vsftpd.conf
COPY images/ftp/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 21 21100-21110
ENTRYPOINT ["/entrypoint.sh"]
