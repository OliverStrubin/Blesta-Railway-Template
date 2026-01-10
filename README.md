# Blesta on Railway (BYO ZIP)

This Railway template deploys a production-ready Blesta runtime:
- PHP 8.1 + Apache
- MySQL
- Persistent volume
- Cron worker service

⚠️ Blesta is commercial software. This template does not redistribute Blesta files.
You must provide your own Blesta ZIP or upload your installation files.

## Quick Deploy
1. Deploy the template on Railway
2. Add a Volume to **web** and **cron**, mount to `/data`
3. (Recommended) Set `BLESTA_ZIP_URL` to a private/signed URL to your Blesta ZIP
4. Open the public URL and complete the Blesta installer

## Environment Variables
### Optional (recommended)
- `BLESTA_ZIP_URL` = URL to your Blesta ZIP (private/signed link)
- `BLESTA_ZIP_SHA256` = verify the ZIP integrity

### MySQL (auto-provided by Railway)
- `MYSQLHOST`, `MYSQLPORT`, `MYSQLDATABASE`, `MYSQLUSER`, `MYSQLPASSWORD`

## Install Notes
Blesta files will be stored under:
- `/data/blesta` (persistent)

The web root redirects to `/blesta/`.

## Cron
A separate `cron` service runs:
- `php /data/blesta/index.php cron` every 5 minutes

## Upgrades
- Replace your ZIP at `BLESTA_ZIP_URL` with a newer version (or update the URL)
- Restart the web service
- Follow Blesta upgrade instructions (backup first)
