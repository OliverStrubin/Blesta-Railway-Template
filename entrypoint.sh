#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/data/blesta}"
WAIT_FOR_DB_SECONDS="${WAIT_FOR_DB_SECONDS:-0}"

BLESTA_AUTO_LATEST="${BLESTA_AUTO_LATEST:-false}"
BLESTA_ZIP_URL="${BLESTA_ZIP_URL:-}"
BLESTA_ZIP_SHA256="${BLESTA_ZIP_SHA256:-}"

echo "[web] Preparing directories..."
mkdir -p "$APP_ROOT" /data/tmp

# -----------------------------
# MySQL check (non-blocking)
# -----------------------------
if [[ -n "${MYSQLHOST:-}" && -n "${MYSQLUSER:-}" && -n "${MYSQLPASSWORD:-}" ]]; then
  echo "[web] Checking MySQL at ${MYSQLHOST}:${MYSQLPORT:-3306} (non-blocking)..."
  if mysqladmin ping -h"${MYSQLHOST}" -P"${MYSQLPORT:-3306}" -u"${MYSQLUSER}" -p"${MYSQLPASSWORD}" --silent >/dev/null 2>&1; then
    echo "[web] MySQL is reachable."
  else
    echo "[web] MySQL not reachable yet (continuing to start web anyway)."
  fi
fi

# -----------------------------
# (Optional) Bootstrap Blesta
# Keep this BEFORE Apache start if you want it done up front,
# or move it after start if you prefer instant responses.
# -----------------------------
if [[ ! -f "${APP_ROOT}/index.php" ]]; then
  ZIP_PATH="/data/tmp/blesta.zip"
  rm -f "$ZIP_PATH"

  if [[ -n "$BLESTA_ZIP_URL" ]]; then
    echo "[web] Downloading Blesta from BLESTA_ZIP_URL..."
    curl -fL --retry 5 --retry-delay 2 --retry-all-errors "$BLESTA_ZIP_URL" -o "$ZIP_PATH"
  elif [[ "$BLESTA_AUTO_LATEST" == "true" ]]; then
    echo "[web] Downloading Blesta from official latest.zip..."
    curl -fL --retry 5 --retry-delay 2 --retry-all-errors "https://www.blesta.com/latest.zip" -o "$ZIP_PATH"
  else
    echo "[web] No Blesta present and no download method configured."
    ZIP_PATH=""
  fi

  if [[ -n "$ZIP_PATH" && -f "$ZIP_PATH" ]]; then
    echo "[web] Extracting Blesta..."
    rm -rf "${APP_ROOT:?}/"*
    unzip -q "$ZIP_PATH" -d "$APP_ROOT"

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

echo "[web] Setting permissions..."
chown -R www-data:www-data /data || true
find "$APP_ROOT" -type d -exec chmod 755 {} \; || true
find "$APP_ROOT" -type f -exec chmod 644 {} \; || true

# -----------------------------
# Configure Apache to listen on Railway PORT
# -----------------------------
PORT="${PORT:-80}"
echo "[web] Configuring Apache to listen on PORT=${PORT}..."

# Ensure ports.conf has exactly one Listen line for PORT
# Replace any existing Listen lines with the desired one.
sed -i 's/^Listen .*$//g' /etc/apache2/ports.conf
# Remove empty lines created by the replacement
grep -v '^[[:space:]]*$' /etc/apache2/ports.conf > /tmp/ports.conf && mv /tmp/ports.conf /etc/apache2/ports.conf
# Append desired Listen
echo "Listen ${PORT}" >> /etc/apache2/ports.conf

# Update vhost port if needed
sed -i "s/<VirtualHost \*:.*>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf || true

# Show config for debugging
echo "[web] Apache ports.conf:"
cat /etc/apache2/ports.conf || true
echo "[web] Apache vhost:"
grep -n "VirtualHost" /etc/apache2/sites-available/000-default.conf || true

# Validate Apache config before starting
echo "[web] Validating Apache config..."
apache2ctl configtest

echo "[web] Starting Apache..."
exec apache2-foreground
