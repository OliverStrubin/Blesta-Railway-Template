#!/usr/bin/env bash
set -u

APP_ROOT="${APP_ROOT:-/data/blesta}"
PORT="${PORT:-80}"

BLESTA_AUTO_LATEST="${BLESTA_AUTO_LATEST:-false}"
BLESTA_ZIP_URL="${BLESTA_ZIP_URL:-}"
BLESTA_ZIP_SHA256="${BLESTA_ZIP_SHA256:-}"

log() { echo "[web] $*"; }

# -----------------------------
# Configure Apache to listen on Railway PORT
# -----------------------------
log "Configuring Apache to listen on PORT=${PORT}..."

# Make ports.conf listen on $PORT (handle any existing Listen lines)
if grep -qE '^\s*Listen\s+' /etc/apache2/ports.conf; then
  sed -i -E "s/^\s*Listen\s+[0-9]+/Listen ${PORT}/g" /etc/apache2/ports.conf
else
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

# Update vhost port
sed -i -E "s/<VirtualHost \*:([0-9]+)>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf || true

log "Validating Apache config..."
apache2ctl configtest

# -----------------------------
# Start Apache immediately (so Railway can route)
# -----------------------------
log "Starting Apache now..."
apache2-foreground &
APACHE_PID=$!

# -----------------------------
# Background setup (doesn't block web)
# -----------------------------
(
  set +e

  log "Preparing directories..."
  mkdir -p "$APP_ROOT" /data/tmp

  # Non-blocking MySQL check (informational only)
  if [[ -n "${MYSQLHOST:-}" && -n "${MYSQLUSER:-}" && -n "${MYSQLPASSWORD:-}" ]]; then
    log "Checking MySQL at ${MYSQLHOST}:${MYSQLPORT:-3306} (non-blocking)..."
    mysqladmin ping -h"${MYSQLHOST}" -P"${MYSQLPORT:-3306}" -u"${MYSQLUSER}" -p"${MYSQLPASSWORD}" --silent >/dev/null 2>&1 \
      && log "MySQL is reachable." \
      || log "MySQL not reachable yet (that's OK)."
  fi

  # Bootstrap Blesta only if not installed
  if [[ ! -f "${APP_ROOT}/index.php" ]]; then
    ZIP_PATH="/data/tmp/blesta.zip"
    rm -f "$ZIP_PATH"

    if [[ -n "$BLESTA_ZIP_URL" ]]; then
      log "Downloading Blesta from BLESTA_ZIP_URL..."
      curl -fL --retry 5 --retry-delay 2 --retry-all-errors "$BLESTA_ZIP_URL" -o "$ZIP_PATH"
    elif [[ "$BLESTA_AUTO_LATEST" == "true" ]]; then
      log "Downloading Blesta from official latest.zip..."
      curl -fL --retry 5 --retry-delay 2 --retry-all-errors "https://www.blesta.com/latest.zip" -o "$ZIP_PATH"
    else
      log "No Blesta present and no download method configured."
      ZIP_PATH=""
    fi

    if [[ -n "$ZIP_PATH" && -f "$ZIP_PATH" ]]; then
      log "Extracting Blesta..."
      rm -rf "${APP_ROOT:?}/"*
      unzip -q "$ZIP_PATH" -d "$APP_ROOT"

      # Handle nested /blesta directory
      if [[ -f "${APP_ROOT}/blesta/index.php" && ! -f "${APP_ROOT}/index.php" ]]; then
        log "Normalizing nested 'blesta/' directory..."
        shopt -s dotglob
        mv "${APP_ROOT}/blesta/"* "$APP_ROOT/"
        rmdir "${APP_ROOT}/blesta" || true
        shopt -u dotglob
      fi

      log "Blesta bootstrap complete."
    fi
  else
    log "Blesta already present in ${APP_ROOT}."
  fi

  # IMPORTANT: Avoid slow recursive chmod/chown on every boot.
  # Only ensure ownership on the app root (not whole /data).
  log "Setting ownership on ${APP_ROOT} (non-recursive)..."
  chown -R www-data:www-data "$APP_ROOT" >/dev/null 2>&1 || true

  log "Background setup finished."
) &

# Keep container alive with Apache
wait $APACHE_PID
