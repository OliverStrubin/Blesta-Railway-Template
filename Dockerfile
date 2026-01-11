# Pin OS to avoid Debian upgrades breaking IMAP deps
FROM php:8.1-apache-bookworm

# -----------------------------
# System dependencies
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    unzip \
    ca-certificates \
    curl \
    default-mysql-client \
    \
    # Needed for PHP extensions
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    \
    # For gmp
    libgmp-dev \
    \
    # For IMAP (UW-IMAP headers)
    libc-client2007e-dev \
    libkrb5-dev \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------
# PHP extensions (Blesta compatible + recommended)
# -----------------------------
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    zip \
    intl \
    gd \
    mbstring \
    xml \
    gmp \
    soap

# IMAP (incoming mail support)
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
 && docker-php-ext-install imap

# Mailparse (incoming mail parsing)
RUN pecl install mailparse \
 && docker-php-ext-enable mailparse

# -----------------------------
# Install ionCube Loader (PHP 8.1)
# -----------------------------
RUN set -eux; \
    cd /tmp; \
    curl -fsSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube.tar.gz; \
    tar xzf ioncube.tar.gz; \
    PHP_EXT_DIR="$(php -r 'echo ini_get("extension_dir");')"; \
    cp ioncube/ioncube_loader_lin_8.1.so "$PHP_EXT_DIR"; \
    echo "zend_extension=ioncube_loader_lin_8.1.so" > /usr/local/etc/php/conf.d/00-ioncube.ini; \
    rm -rf /tmp/ioncube /tmp/ioncube.tar.gz

# -----------------------------
# Apache modules
# -----------------------------
RUN a2enmod rewrite headers expires

# -----------------------------
# HARD-FORCE single Apache MPM (prefork)
# -----------------------------
RUN set -eux; \
    a2dismod mpm_event mpm_worker mpm_prefork || true; \
    rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf || true; \
    a2enmod mpm_prefork

# -----------------------------
# Apache vhost + healthcheck
# -----------------------------
COPY apache-blesta.conf /etc/apache2/sites-available/000-default.conf
COPY healthcheck.php /var/www/html/healthcheck.php

# -----------------------------
# Entrypoints
# -----------------------------
COPY entrypoint.sh /entrypoint.sh
COPY cron.sh /cron.sh

# Normalize scripts (CRLF-safe) and ensure executable
RUN sed -i 's/\r$//' /entrypoint.sh /cron.sh \
 && chmod +x /entrypoint.sh /cron.sh

# -----------------------------
# Environment defaults
# -----------------------------
ENV APP_ROOT=/data/blesta \
    WEB_ROOT=/var/www/html \
    PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_POST_MAX_SIZE=64M

EXPOSE 80
ENTRYPOINT ["bash", "/entrypoint.sh"]
