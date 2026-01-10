BLESTA_AUTO_LATEST="${BLESTA_AUTO_LATEST:-false}"

if [[ ! -f "${APP_ROOT}/index.php" ]]; then
  ZIP_PATH="/data/tmp/blesta.zip"
  rm -f "$ZIP_PATH"

  if [[ -n "${BLESTA_ZIP_URL:-}" ]]; then
    echo "[web] Downloading Blesta from BLESTA_ZIP_URL..."
    curl -fsSL "$BLESTA_ZIP_URL" -o "$ZIP_PATH"
  elif [[ "$BLESTA_AUTO_LATEST" == "true" ]]; then
    echo "[web] Downloading Blesta from official latest.zip..."
    curl -fsSL "https://www.blesta.com/latest.zip" -o "$ZIP_PATH"
  else
    echo "[web] No Blesta present and no download method configured."
    echo "[web] Set BLESTA_ZIP_URL or set BLESTA_AUTO_LATEST=true."
    ZIP_PATH=""
  fi

  if [[ -n "$ZIP_PATH" && -f "$ZIP_PATH" ]]; then
    echo "[web] Extracting..."
    rm -rf "${APP_ROOT:?}/"*
    unzip -q "$ZIP_PATH" -d "$APP_ROOT"

    if [[ -f "${APP_ROOT}/blesta/index.php" && ! -f "${APP_ROOT}/index.php" ]]; then
      echo "[web] Normalizing nested 'blesta/' directory..."
      shopt -s dotglob
      mv "${APP_ROOT}/blesta/"* "$APP_ROOT/"
      rmdir "${APP_ROOT}/blesta" || true
      shopt -u dotglob
    fi

    echo "[web] Bootstrap done."
  fi
fi
