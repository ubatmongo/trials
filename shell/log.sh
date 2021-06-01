#!/usr/bin/env zsh -l

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
WHITE="\e[97m"
ENDCOLOR="\e[0m"

_log_message () {
  echo -e "${WHITE}$1${ENDCOLOR}"
}

_log_header () {
  _log_message "\n$1"
  _log_message "##########################\n"
}

_log_success () {
  echo -e "${GREEN}$1${ENDCOLOR}"
}

_log_warn () {
  echo -e "${YELLOW}$1${ENDCOLOR}"
}

_log_fail () {
  echo -e "${RED}$1${ENDCOLOR}"
}
