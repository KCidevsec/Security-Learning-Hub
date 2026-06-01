# Kali attacker box with an in-browser shell (ttyd).
#
# Multi-arch: build with `docker buildx --platform linux/amd64,linux/arm64`.
# BuildKit provides TARGETARCH automatically; we use it to fetch the right ttyd binary.
#
# Metasploit is OPT-IN (--build-arg INSTALL_METASPLOIT=true): it is multi-GB and slows
# builds dramatically. The leaner default keeps per-student pods small. Add it when an
# exercise needs it.
FROM kalilinux/kali-rolling:latest

LABEL org.opencontainers.image.title="kali-ttyd"
LABEL org.opencontainers.image.description="Kali attacker box + ttyd browser shell for Security-Learning-Hub v2"
LABEL maintainer="Kyriakos Costa"

ARG INSTALL_METASPLOIT=false
# TARGETARCH is injected by buildx: amd64 | arm64
ARG TARGETARCH
ARG TTYD_VERSION=1.7.7

ENV DEBIAN_FRONTEND=noninteractive

# Core attacker tooling. Kept deliberately lean; extend per exercise as needed.
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
        nmap \
        netcat-traditional \
        curl \
        wget \
        sqlmap \
        hydra \
        dnsutils \
        iputils-ping \
        net-tools \
        mariadb-client \
        openssh-client \
        python3 \
        python3-pip \
        ssh-audit \
        ca-certificates \
        less \
        vim-tiny \
        bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Optional: full Metasploit framework (large).
RUN if [ "$INSTALL_METASPLOIT" = "true" ]; then \
        apt-get update && apt-get install -y --no-install-recommends metasploit-framework \
        && rm -rf /var/lib/apt/lists/*; \
    fi

# ttyd: serve a shell over websocket. Pull the static binary matching the target arch.
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) TTYD_ARCH="x86_64" ;; \
        arm64) TTYD_ARCH="aarch64" ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    wget -O /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH}"; \
    chmod +x /usr/local/bin/ttyd; \
    ttyd --version

# Mount point for the per-student persistent share (exploits, notes, loot).
RUN mkdir -p /root/kali_share_folder
WORKDIR /root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ttyd listens here; exposed via Service/Ingress (or port-forward for local dev).
EXPOSE 7681

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
