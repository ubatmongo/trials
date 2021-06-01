#!/usr/bin/env zsh -l
source log.sh
source installer.sh

# check if virtualbox is installed
_log_header "check virtualbox and install"
if ! [ command -v virtualbox &> /dev/null ]; then
  _log_message "installing virtualbox"
  _install_dmg "https://download.virtualbox.org/virtualbox/6.1.22/VirtualBox-6.1.22-144080-OSX.dmg" "VirtualBox"
  _log_success "successfully installed virtualbox"
else
  _log_message "virtualbox is already installed"
fi

brew tap hashicorp/tap
brew install vagrant
