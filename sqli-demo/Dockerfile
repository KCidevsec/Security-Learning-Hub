# Dockerfile
FROM php:8.1-apache

# Install additional tools for demonstration
RUN apt-get update && apt-get install -y \
    sudo \
    net-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install mysqli extension
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Create a privileged user 'webadmin' with sudo access
RUN useradd -m -s /bin/bash webadmin && \
    echo "webadmin:password123" | chpasswd && \
    usermod -aG sudo webadmin && \
    echo "webadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add www-data to group 999 (MySQL's group ID)
# This allows www-data to read files created by MySQL
RUN groupadd -g 999 mysql 2>/dev/null || true && \
    usermod -aG 999 www-data

# Add webadmin and www-data to each other's groups
RUN usermod -aG webadmin www-data && \
    usermod -aG www-data webadmin

# Set working directory
WORKDIR /var/www/html

# Add a warning label
LABEL warning="This container has relaxed permissions - FOR EDUCATIONAL USE ONLY"

EXPOSE 80