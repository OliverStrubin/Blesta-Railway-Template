# Blesta on Railway (Auto-Install Latest)

A production-ready Railway template for deploying **Blesta** with PHP, MySQL, persistent storage, and cron — with automatic installation of the latest Blesta release or support for a user-provided ZIP.

⚠️ **Important**  
Blesta is commercial software.  
This template does **not** provide a Blesta license. You must supply your own license to use the software.

---

## Features

- PHP 8.1 + Apache (Blesta compatible)
- MySQL database (Railway managed)
- Persistent volume (safe redeploys & upgrades)
- Dedicated cron worker (required by Blesta)
- Auto-install latest Blesta on first deploy
- Optional custom ZIP support (private/signed URL)
- Healthcheck endpoint for reliable deployments

---

## One-Click Deploy

1. Click **Deploy on Railway**
2. Wait for services to provision
3. Open your Railway domain
4. Complete the Blesta web installer
5. Enter your Blesta license key

---

## How Installation Works

On first deploy:

- If `BLESTA_AUTO_LATEST=true` (default), the container downloads:
  https://www.blesta.com/latest.zip
- If `BLESTA_ZIP_URL` is set, that ZIP is downloaded instead
- Files are extracted into a persistent volume
- The installer is available immediately

No manual uploads required.

---

## Services Included

| Service | Purpose |
|-------|--------|
| web | PHP + Apache (Blesta UI) |
| mysql | Blesta database |
| cron | Runs Blesta background tasks |

---

## Persistent Storage

Blesta files are stored at:

/data/blesta

This path is backed by a Railway volume.

⚠️ Do not remove the volume after installation or data will be lost.

---

## Environment Variables

### MySQL (auto-provided by Railway)

- MYSQLHOST
- MYSQLPORT
- MYSQLDATABASE
- MYSQLUSER
- MYSQLPASSWORD

### Optional Variables

| Variable | Default | Description |
|--------|--------|------------|
| BLESTA_AUTO_LATEST | true | Auto-install latest Blesta |
| BLESTA_ZIP_URL | (empty) | Custom Blesta ZIP URL |
| BLESTA_ZIP_SHA256 | (empty) | ZIP integrity verification |
| WAIT_FOR_DB_SECONDS | 60 | DB wait timeout |
| PHP_MEMORY_LIMIT | 256M | PHP memory limit |
| PHP_UPLOAD_MAX_FILESIZE | 64M | Upload limit |
| PHP_POST_MAX_SIZE | 64M | POST limit |

If both BLESTA_ZIP_URL and BLESTA_AUTO_LATEST are set, BLESTA_ZIP_URL takes priority.

---

## Cron

The cron service runs:

php /data/blesta/index.php cron

Every 5 minutes automatically. Logs are visible in Railway.

---

## Healthcheck

The web service exposes:

/healthcheck.php

Used by Railway to ensure reliable restarts.

---

## Upgrading Blesta

1. Replace the ZIP at BLESTA_ZIP_URL with a newer version
2. Restart the web service
3. Follow Blesta upgrade instructions

Always back up first.

---

## Licensing Notice

This template:
- Does not include a Blesta license
- Does not redistribute Blesta files
- Automates download from Blesta’s official source or a user-provided URL

You are responsible for complying with Blesta’s license terms.

---

## Troubleshooting

- Installer not loading → check web service logs
- Database errors → verify MySQL variables
- Cron not running → check cron service logs
- Files missing after redeploy → ensure /data volume is mounted

---

## Community

This template is community-maintained. Contributions and improvements are welcome.
