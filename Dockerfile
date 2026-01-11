FROM php:8.1-apache

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip ca-certificates curl \
    libzip-dev libpng-dev libonig-dev libxml2-dev libicu-dev \
    default-mysql-client \
  && rm -rf /var/lib/apt/lists/*

# PHP extensions commonly required/used by Blesta
RUN docker-php-ext-install \
    pdo pdo_mysql zip intl gd mbstring xml

# Apache modules
RUN a2enmod rewrite headers expires

# Ensure only one Apache MPM is enabled (php:apache expects prefork)
RUN a2dismod mpm_event mpm_worker || true && a2enmod mpm_prefork

# Custom vhost + php.ini overrides via env
COPY apache-blesta.conf /etc/apache2/sites-available/000-default.conf
COPY healthcheck.php /var/www/html/healthcheck.php

# Entrypoints
COPY entrypoint.sh /entrypoint.sh
COPY cron.sh /cron.sh
RUN sed -i 's/\r$//' /entrypoint.sh /cron.sh && chmod +x /entrypoint.sh /cron.sh


# Reasonable defaults
ENV APP_ROOT=/data/blesta \
    WEB_ROOT=/var/www/html \
    PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_POST_MAX_SIZE=64M

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
