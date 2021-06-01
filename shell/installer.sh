#!/usr/bin/env zsh -l
source log.sh

_install_dmg () {
  DOWNLOAD_URL="$1"
  APP_NAME="$2"

  if [ -e "/Applications/${APP_NAME}.app" ]; then
    _log_success "${APP_NAME} is already installed"
    exit 1
  fi

  tmp_mount=`/usr/bin/mktemp -d /tmp/${APP_NAME}`
  echo $tmp_mount

  # Attach the install DMG directly from app
  hdiutil attach "$( eval echo "${DOWNLOAD_URL}" )" -nobrowse -quiet -mountpoint "${tmp_mount}"

  ls -l "$tmp_mount"
  ls -l "${tmp_mount}/${APP_NAME}.app"
  #rm -dfR "/Applications/${APP_NAME}.app"

  ditto "${tmp_mount}/${APP_NAME}.app" "/Applications/${APP_NAME}.app"

  # Let things settle down
  sleep 1

  # Detach the dmg and remove the temporary mountpoint
  hdiutil detach "${tmp_mount}" && /bin/rm -rf "${tmp_mount}"

  if [ -e "/Applications/${APP_NAME}.app" ]; then
    _log_success "${APP_NAME} is installed"
  fi
}
