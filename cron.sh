#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/data/blesta}"
WAIT_FOR_DB_SECONDS="${WAIT_FOR_DB_SECONDS:-60}"

echo "[cron] Starting cron worker. App root: ${APP_ROOT}"

# Wait for MySQL
if [[ -n "${MYSQLHOST:-}" && -n "${MYSQLUSER:-}" && -n "${MYSQLPASSWORD:-}" ]]; then
  echo "[cron] Waiting for MySQL at ${MYSQLHOST}:${MYSQLPORT:-3306} (up to ${WAIT_FOR_DB_SECONDS}s)..."
  end=$((SECONDS + WAIT_FOR_DB_SECONDS))
  until mysqladmin ping -h"${MYSQLHOST}" -P"${MYSQLPORT:-3306}" -u"${MYSQLUSER}" -p"${MYSQLPASSWORD}" --silent >/dev/null 2>&1; do
    if (( SECONDS >= end )); then
      echo "[cron] MySQL not ready yet; continuing anyway."
      break
    fi
    sleep 2
  done
fi

while true; do
  if [[ -f "${APP_ROOT}/index.php" ]]; then
    echo "[cron] Running Blesta cron..."
    php "${APP_ROOT}/index.php" cron || echo "[cron] Cron run failed (will retry)."
  else
    echo "[cron] Blesta not installed yet. Waiting..."
  fi
  sleep 300
done
