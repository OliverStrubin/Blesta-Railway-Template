FROM php:8.1-apache

# -----------------------------
# System dependencies
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    unzip \
    ca-certificates \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    default-mysql-client \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------
# PHP extensions (Blesta compatible)
# -----------------------------
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    zip \
    intl \
    gd \
    mbstring \
    xml

# -----------------------------
# Apache modules
# -----------------------------
RUN a2enmod rewrite headers expires

# -----------------------------
# HARD-FORCE SINGLE APACHE MPM (prefork)
# Prevents "More than one MPM loaded"
# -----------------------------
RUN set -eux; \
    a2dismod mpm_event mpm_worker mpm_prefork || true; \
    rm -f /etc/apache2/mods-enabled/mpm_*.load /etc/apache2/mods-enabled/mpm_*.conf || true; \
    a2enmod mpm_prefork; \
    apache2ctl -M | grep mpm

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

# -----------------------------
# Railway uses dynamic PORT
# -----------------------------
EXPOSE 80

# Use bash explicitly (avoids exec format edge cases)
ENTRYPOINT ["bash", "/entrypoint.sh"]
