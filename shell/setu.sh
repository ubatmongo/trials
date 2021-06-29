# !/usr/bin/env zsh -l

set -u
# DEVELOPER_DIR="DEVELOPER_DIRDEVELOPER_DIRDEVELOPER_DIR"
echo ${DEVELOPER_DIR:-default}
# echo ${DEVELOPER_DIR}

if [ -z "${DEVELOPER_DIR:-}" ]; then
  echo "ohh lala no DEVELOPER_DIR"
else
  echo "hah! ${DEVELOPER_DIR:-default}"
fi
