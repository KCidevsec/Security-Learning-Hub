# Vulnerable PHP/Apache front-end for the SQLi exercise.
#
# Multi-arch (php:8.1-apache publishes amd64 + arm64). The app is baked into /opt/app;
# at pod start an init container copies it into a shared volume mounted at /var/www/html,
# which MySQL also mounts. That shared web root is what makes the
# `UNION ... INTO OUTFILE '/var/www/html/shell.php'` webshell chain work.
FROM php:8.1-apache

LABEL org.opencontainers.image.title="sqli-demo-web"
LABEL org.opencontainers.image.description="Intentionally vulnerable SQLi front-end (Security-Learning-Hub v2)"
LABEL warning="Intentionally vulnerable. Educational use only. Never expose to the internet."

RUN apt-get update && apt-get install -y --no-install-recommends \
        net-tools procps \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install mysqli \
    && docker-php-ext-enable mysqli \
    && a2enmod rewrite \
    # Let Apache (www-data) read files MySQL (gid 999) drops via INTO OUTFILE — the other
    # half of the webshell chain (paired with `umask 0002` on the DB in the manifest).
    && groupadd -g 999 mysql 2>/dev/null || true \
    && usermod -aG 999 www-data

# Bake the app into a staging dir. The init container copies it into the shared
# web root at runtime (mounting an emptyDir at /var/www/html would otherwise shadow it).
COPY src/ /opt/app/

EXPOSE 80
