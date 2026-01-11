#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Make Apache listen on Railway PORT
# -----------------------------
PORT="${PORT:-80}"
echo "[web] Configuring Apache to listen on PORT=${PORT}..."

# Update ports.conf
if grep -q "^Listen 80" /etc/apache2/ports.conf; then
  sed -i "s/^Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
else
  # if Listen is different, ensure desired port is present
  sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf || true
fi

# Update default vhost to match port
sed -i "s/<VirtualHost \*:80>/<VirtualHost \*:${PORT}>/" /etc/apache2/sites-available/000-default.conf || true


# -----------------------------
# Config
# -----------------------------
APP_ROOT="${APP_ROOT:-/data/blesta}"
WEB_ROOT="${WEB_ROOT:-/var/www/html}"
WAIT_FOR_DB_SECONDS="${WAIT_FOR_DB_SECONDS:-60}"

BLESTA_AUTO_LATEST="${BLESTA_AUTO_LATEST:-false}"
BLESTA_ZIP_URL="${BLESTA_ZIP_URL:-}"
BLESTA_ZIP_SHA256="${BLESTA_ZIP_SHA256:-}"

# -----------------------------
# PHP configuration
# -----------------------------
PHP_INI="/usr/local/etc/php/conf.d/99-railway.ini"
cat > "$PHP_INI" <<EOF
memory_limit=${PHP_MEMORY_LIMIT:-256M}
upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE:-64M}
post_max_size=${PHP_POST_MAX_SIZE:-64M}
max_execution_time=60
date.timezone=UTC
EOF

# -----------------------------
# Prepare directories
# -----------------------------
echo "[web] Preparing directories..."
mkdir -p "$APP_ROOT" /data/tmp

# -----------------------------
# Wait for MySQL
# -----------------------------
if [[ -n "${MYSQLHOST:-}" && -n "${MYSQLUSER:-}" && -n "${MYSQLPASSWORD:-}" ]]; then
  echo "[web] Checking MySQL at ${MYSQLHOST}:${MYSQLPORT:-3306} (non-blocking)..."
  if mysqladmin ping \
      -h"${MYSQLHOST}" \
      -P"${MYSQLPORT:-3306}" \
      -u"${MYSQLUSER}" \
      -p"${MYSQLPASSWORD}" \
      --silent >/dev/null 2>&1; then
    echo "[web] MySQL is reachable."
  else
    echo "[web] MySQL not reachable yet (continuing to start web anyway)."
  fi
fi


# -----------------------------
# Bootstrap Blesta
# -----------------------------
if [[ ! -f "${APP_ROOT}/index.php" ]]; then
  ZIP_PATH="/data/tmp/blesta.zip"
  rm -f "$ZIP_PATH"

  if [[ -n "$BLESTA_ZIP_URL" ]]; then
    echo "[web] Downloading Blesta from BLESTA_ZIP_URL..."
    curl -fL --retry 5 --retry-delay 2 "$BLESTA_ZIP_URL" -o "$ZIP_PATH"
  elif [[ "$BLESTA_AUTO_LATEST" == "true" ]]; then
    echo "[web] Downloading Blesta from official latest.zip..."
    curl -fL --retry 5 --retry-delay 2 \
      "https://www.blesta.com/latest.zip" -o "$ZIP_PATH"
  else
    echo "[web] No Blesta present and no download method configured."
    ZIP_PATH=""
  fi

  if [[ -n "$ZIP_PATH" && -f "$ZIP_PATH" ]]; then
    echo "[web] Extracting Blesta..."
    rm -rf "${APP_ROOT:?}/"*
    unzip -q "$ZIP_PATH" -d "$APP_ROOT"

    # Handle nested /blesta directory
    if [[ -f "${APP_ROOT}/blesta/index.php" && ! -f "${APP_ROOT}/index.php" ]]; then
      echo "[web] Normalizing nested 'blesta/' directory..."
      shopt -s dotglob
      mv "${APP_ROOT}/blesta/"* "$APP_ROOT/"
      rmdir "${APP_ROOT}/blesta" || true
      shopt -u dotglob
    fi

    echo "[web] Blesta bootstrap complete."
  fi
fi

# -----------------------------
# Permissions
# -----------------------------
echo "[web] Setting permissions..."
chown -R www-data:www-data /data || true
find "$APP_ROOT" -type d -exec chmod 755 {} \; || true
find "$APP_ROOT" -type f -exec chmod 644 {} \; || true

# -----------------------------
# Start Apache
# -----------------------------
echo "[web] Starting Apache..."
echo "[web] Starting Apache..."
apache2-foreground &
APACHE_PID=$!

# If Blesta not installed, bootstrap in background (doesn't block Railway routing)
if [[ ! -f "${APP_ROOT}/index.php" ]]; then
  echo "[web] Bootstrapping in background..."
  # (keep your existing bootstrap code here)
fi

wait $APACHE_PID
exec apache2-foreground

