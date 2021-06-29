#!/usr/bin/env zsh -l
_awscli_install () {
    echo "Installing the AWS CLI"

    change_xml="$(mktemp -t choiceChanges).xml"
    cat > "$change_xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
    <dict>
      <key>attributeSetting</key>
      <string>$HOME</string>
      <key>choiceAttribute</key>
      <string>customLocation</string>
      <key>choiceIdentifier</key>
      <string>default</string>
    </dict>
</array>
</plist>
EOF

    pkg="$(mktemp -t awscli).pkg"
    curl --output "$pkg" --silent --show-error --fail "https://awscli.amazonaws.com/AWSCLIV2.pkg"

    installer -pkg "$pkg" -target CurrentUserHomeDirectory -applyChoiceChangesXML "$change_xml"
}

_awscli_make_symlinks () {
    echo "Making symlinks in ~/bin"
    pushd ~/bin
    ln -s ../aws-cli/aws ../aws-cli/aws_completer .
    popd
    rehash
}

awscli () {
    # dependencies
    homebin

    echo "Looking for the AWS CLI"
    if ! which aws; then
        if ! pkgutil --info com.amazon.aws.cli2 --volume ~; then
            _awscli_install
        fi

        _awscli_make_symlinks
    fi
}
awsscratch () {
    # dependencies
    awscli
    mms_repo

    scratch_account_id="358363220050"
    conf_local_secure="$MMS_HOME/server/conf/conf-local-secure.properties"
    access_key=""
    secret_key=""
    keys_from_conf_local_secure=""
    if [ -r "$conf_local_secure" ]; then
        echo "Reading keys from existing conf-local-secure.properties"
        while read -r line; do
            key_value=("${(@s/=/)line}")
            if [ "${key_value[1]}" = "local.aws.accessKey" ]; then
                access_key="${key_value[2]}"
            elif [ "${key_value[1]}" = "local.aws.secretKey" ]; then
                secret_key="${key_value[2]}"
            fi
        done < "$conf_local_secure"
        keys_from_conf_local_secure="1"
    elif [ -n "${ONBOARDING_AWS_ACCESS_KEY:-}" ]; then
        # Automated testing
        access_key="$ONBOARDING_AWS_ACCESS_KEY"
        secret_key="$ONBOARDING_AWS_SECRET_KEY"
    else
        echo "Your lead sent you an email containing AWS API keys. Please paste them here."
        echo -n "Access key ID: "
        read -r access_key
        echo -n "Secret key: "
        read -rs secret_key
        echo ""
        echo "One more thing for AWS. In your lead's email you were given a temporary password to log in to the console."
        echo "Please go to https://mms-scratch.signin.aws.amazon.com/"
        echo "At the top right, click 'My Account', then 'AWS Management Console'."
        echo "Log in, and change your password"
        echo ""
        echo "To prove you've done this, after signing in, go to https://console.aws.amazon.com/iam/home?#/users"
        echo "Find yourself in the list and click on the name"
        echo -n "Copy and paste your User ARN here: "
        read -r user_arn
        if ! echo "$user_arn" | grep -q "$scratch_account_id"; then
            echo "That's not correct. Please re-run the script and try again."
            exit 1
        fi
    fi

    if [ -z "$access_key" ] || [ -z "$secret_key" ]; then
        echo "Either access key ID or secret key weren't provided"
        if [ -r "$conf_local_secure" ]; then
            echo "This script tried to find keys in an existing $conf_local_secure file"
        fi
        exit 1
    fi

    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    account_id="$(aws --output text --query Account sts get-caller-identity)"

    if [ "$account_id" = "$scratch_account_id" ]; then
        if [ -z "$keys_from_conf_local_secure" ]; then
            echo "Writing to conf-local-secure.properties for your local MMS server"
            echo "local.aws.accessKey=$access_key" >> "$conf_local_secure"
            echo "local.aws.secretKey=$secret_key" >> "$conf_local_secure"
            jira_user="$(aws --output text --query Arn sts get-caller-identity | cut -d / -f 2)"
            echo "local.global.user=$jira_user" >> "$conf_local_secure"
        fi

        aws configure set region us-east-1 --profile mms-scratch
        aws configure set aws_access_key_id "$access_key" --profile mms-scratch
        aws configure set aws_secret_access_key "$secret_key" --profile mms-scratch
    else
        echo "The keys provided were not for the mms-scratch AWS account"
        if [ -r "$conf_local_secure" ]; then
            echo "This script tried to use keys in an existing $conf_local_secure file"
            echo "Those keys are not for the correct account, back them up and remove that file"
        fi
        exit 1
    fi
}
bazelisk_setup () {
    # Dependencies
    xcode_setup
    homebin
    zsh_completion_setup
    mms_repo

    echo "Installing/updating bazelisk"
    curl --location --output ~/bin/bazel --silent --show-error --fail "https://github.com/bazelbuild/bazelisk/releases/download/v1.8.0/bazelisk-darwin-amd64"
    chmod +x ~/bin/bazel
    rehash

    if ! [ -r ~/.zsh/completion/_bazel ]; then
        echo "Installing shell completion for bazel. You'll have to restart your shell."
        bazel_zsh_completion ~/.zsh/completion/_bazel
    else
        echo "You already have a bazel zsh completion installed so no changes were made"
    fi

    if ! [ -r "$MMS_HOME/.bazelrc.local" ]; then
        mkdir "$MMS_HOME/server/mongodb-releases"
        echo "Setting up defaults in .bazelrc.local"
        cat > "$MMS_HOME/.bazelrc.local" << EOF
build \
    --define=AGENTS_DIR=$MMS_HOME/server/mongodb-releases \
    --define=RELEASE_DIR=$MMS_HOME/server/mongodb-releases \
    --sandbox_writable_path=$MMS_HOME/server/mongodb-releases \
    --define=TEST_DAEMON_ROOT_DIR=$MMS_HOME/server/test_dbs/

build --define=CLIENT_BUILD_ENVIRONMENT=development
build --javacopt="-XepDisableAllChecks"
EOF
    else
        echo "Your existing .bazelrc.local was left alone"
        echo "Seach for '.bazelrc.local' on the following Wiki page to see if there are any new recommendations"
        echo "https://wiki.corp.mongodb.com/display/MMS/Bazel+HOWTO"
    fi
}
zsh_completion_setup () {
    mkdir -p ~/.zsh/completion
    if ! grep -q ".zsh/completion" ~/.zshrc; then
        echo 'Adding ~/.zsh/completion to $fpath'
        echo 'fpath[1,0]=$HOME/.zsh/completion' >> ~/.zshrc
    else
        echo "~/.zsh/completion is already in your fpath, no changes were made"
    fi

    if ! grep -q compinit ~/.zshrc; then
        echo "Setting up zsh completion. You'll have to restart your shell."
        compinit="compinit ${ONBOARDING_COMPINIT:-}"
        cat >> ~/.zshrc << EOF
# The following lines were added by compinstall
zstyle :compinstall filename '$HOME/.zshrc'

autoload -Uz compinit
$compinit
# End of lines added by compinstall
EOF
    else
        echo "compinit was already found in your ~/.zshrc so no changes were made"
    fi

    if ! grep -q use-cache ~/.zshrc; then
        mkdir -p ~/.zsh/cache
        cat >> ~/.zshrc << EOF
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
EOF
    else
        echo "Completion caching directives were already found in your ~/.zshrc so no changes were made"
    fi
}
_github_check_login () {
    if ssh git@github.com 2> /dev/null; then
        echo "Should never happen, ssh to git always fails with 'does not provide shell access'"
        echo "Report in #cloud-dev-prod on Slack if this happens to you"
        exit 1
    else
        ssh_exit_status=$?
        if [ $ssh_exit_status = 255 ]; then
            return 1
        else
            return 0
        fi
    fi
}

_github_ssh_setup () {
    echo "You'll be prompted to enter a passphrase for the new key"
    ssh-keygen -b 4096 -f ~/.ssh/github_rsa -t rsa

    echo "This key will now be added to your Mac's Keychain."
    echo "You'll be prompted to enter the passphrase one more time."
    ssh-add -K ~/.ssh/github_rsa

    if ! grep -q "^Host github.com" ~/.ssh/config; then
        echo "Adding host config section for github.com to ~/.ssh/config"
        echo "Host github.com" >> ~/.ssh/config
        echo "  User git" >> ~/.ssh/config
        echo "  IdentityFile ~/.ssh/github_rsa" >> ~/.ssh/config
        echo "  UseKeychain yes" >> ~/.ssh/config
    else
        echo "You already had a host config section for github.com in ~/.ssh/config so no changes were made"
    fi

    echo ""
    echo "Now you need to add the new key to your GitHub account"
    echo "First, copy and paste this text:"
    echo ""
    cat ~/.ssh/github_rsa.pub
    echo ""
    echo "Then, go to (or Cmd+doubleclick) https://github.com/settings/ssh/new, paste, and press the green button"

    echo ""
    echo "This script will wait for the key to be added"
    echo "Press Ctrl+C if you can't get into your GitHub account to add it right now. You'll be able to re-run it later to pick up where you left off."
    sleep 10 # a long sleep at the beginning appears to make it easier to go to url in terminal
    while ! _github_check_login; do
        echo -n .
        sleep 5
    done

    echo "\a"
    echo "You logged into GitHub!"
    # sleep one more time
    # work around issue that happened once where ssh succeeded but didn't have access to 10gen/mms
    sleep 3
}

_github_ensure_known_hosts () {
    echo "Ensuring github.com is in your SSH known hosts"
    if ! grep -q github.com ~/.ssh/known_hosts; then
        echo "Adding github.com server SSH key"
        mkdir -p ~/.ssh
        echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' \
            >> ~/.ssh/known_hosts
    fi
}

github () {
    _github_ensure_known_hosts

    if ! _github_check_login; then
        echo "You couldn't SSH to GitHub, so this script is generating a new key to add to your account"
        _github_ssh_setup
    fi
}
homebin () {
    echo "Creating bin directory in $HOME if it doesn't exist"
    [ -d ~/bin ] || mkdir ~/bin

    if ! [[ -o login ]]; then
        echo "This script needs to be run in as a login shell"
        echo "If you're running through curl, make sure you're piping to zsh -l, not zsh"
        echo "If you're running a downloaded copy, run: zsh -l preonboarding.sh"
        exit 1
    fi

    if ! [[ ${path[(i)$HOME/bin]} -le ${#path} ]]; then
        echo "Adding ~/bin to your path"
        echo '[[ ${path[(i)$HOME/bin]} -le ${#path} ]] || path=($HOME/bin $path)' >> ~/.zprofile
        path=("$HOME/bin" $path)
        rehash
    fi
}
mms_repo () {
    # Dependencies
    github
    xcode_setup

    if [ -z "${MMS_HOME:-}" ]; then
        echo "You didn't have an MMS_HOME environment variable, so defaulting the clone to ~/mms"
        export MMS_HOME=~/mms
    fi
    if ! grep -q 'export MMS_HOME=' ~/.zshenv; then
        echo "Also adding it to ~/.zshenv so it will always be available"
        echo 'export MMS_HOME=~/mms' >> ~/.zshenv
    else
        echo "MMS_HOME export was found in your ~/.zshenv, so no changes were made"
    fi

    if ! [ -d "$MMS_HOME/.git" ]; then
        echo "Cloning mms"
        if ! git clone git@github.com:10gen/mms "$MMS_HOME"; then
            echo "If you got an error about not having the correct access rights,"
            echo "make sure you requested access to 10gen Cloud in MANA"
            echo "(check for an email from your lead when you started)"
            exit 1
        fi
    else
        echo "You already have a clone of mms so no git operations ran"
    fi
}
xcode_setup () {
    echo "Checking for Xcode"
    if xcodebuild -version; then
        echo "You have Xcode installed"
        if ! xcodebuild -checkFirstLaunchStatus; then
            echo "Enter your password to read & accept the Xcode license and run first launch tasks"
            sudo xcodebuild -runFirstLaunch
        fi
    else
        echo "Xcode is not active"
        if [ -z "$DEVELOPER_DIR" ]; then
            if [ -d /Library/Developer/CommandLineTools ]; then
                if [ -d /Applications/Xcode.app ]; then
                    echo "Xcode is installed, activating it. You may be prompted for password."
                    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
                else
                    echo "You may have Xcode installed, but your active developer directory"
                    echo "may be pointed to command line tools only"
                    echo "If you have Xcode somewhere, run: sudo xcode-select --switch <path>"
                    echo "Otherwise: install Xcode from the Mac App Store"
                    echo "Then, re-run this script"
                fi

            else
                echo "You need to install Xcode from the Mac App Store and re-run this script"
            fi
        else
            echo "You have the DEVELOPER_DIR environment variable set to $DEVELOPER_DIR which is not a valid Xcode installation. "
            echo "Please set it to a valid Xcode installation, or unset it to allow auto-detection to take place"
            echo "Then re-run this script."

        fi
        exit 1
    fi
}
bazel_zsh_completion () {
cat > $1 << 'EOF'
#compdef bazel

# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Installation
# ------------
#
# 1. Add this script to a directory on your $fpath:
#     fpath[1,0]=~/.zsh/completion/
#     mkdir -p ~/.zsh/completion/
#     cp scripts/zsh_completion/_bazel ~/.zsh/completion
#
# 2. Optionally, add the following to your .zshrc.
#     zstyle ':completion:*' use-cache on
#     zstyle ':completion:*' cache-path ~/.zsh/cache
#
#   This way, the completion script does not have to parse Bazel's options
#   repeatedly.  The directory in cache-path must be created manually.
#
# 3. Restart the shell
#
# Options
# -------
#  completion:init:bazel:* cache-lifetime
#    Lifetime for the completion cache (if turned on, default: 1 week)

local curcontext="$curcontext" state line

: ${BAZEL_COMPLETION_PACKAGE_PATH:=%workspace%}
: ${BAZEL:=bazel}
b() { ${BAZEL} --noblock_for_lock "$@" 2>/dev/null; }

# Default cache lifetime is 1 week
zstyle -s ":completion:${curcontext}:" cache-lifetime lifetime
if [[ -z "${lifetime}" ]]; then
  lifetime=$((60*60*24*7))
fi

_bazel_cache_policy() {
  local -a oldp
  oldp=( "$1"(Nms+${lifetime}) )
  (( $#oldp ))
}

_set_cache_policy() {
  zstyle -s ":completion:*:$curcontext*" cache-policy update_policy

  if [[ -z "$update_policy" ]]; then
    zstyle ":completion:$curcontext*" cache-policy _bazel_cache_policy
  fi
}

# Skips over all global arguments.  After invocation, OFFSET contains the
# position of the bazel command in $words.
_adapt_subcommand_offset() {
  OFFSET=2
  for w in ${words[2,-1]}; do
    if [[ $w == (#b)-* ]]; then
      (( OFFSET++ ))
    else
      return
    fi
  done
}

# Retrieve the cache but also check that the value is not empty.
_bazel_safe_retrieve_cache() {
  _retrieve_cache $1 && [[ ${(P)#2} -gt 0 ]]
}

# Puts the name of the variable that contains the options for the bazel
# subcommand handed in as the first argument into the global variable
# _bazel_cmd_options.
_bazel_get_options() {
  local lcmd=$1
  _bazel_cmd_options=_bazel_${lcmd}_options
  _bazel_cmd_args=_bazel_${lcmd}_args
  if [[ ${(P)#_bazel_cmd_options} != 0 ]]; then
    return
  fi
  if _cache_invalid BAZEL_${lcmd}_options || _cache_invalid BAZEL_${lcmd}_args \
    || ! _bazel_safe_retrieve_cache BAZEL_${lcmd}_options ${_bazel_cmd_options} \
    || ! _retrieve_cache BAZEL_${lcmd}_args ${_bazel_cmd_args}; then
    if ! eval "$(b help completion)"; then
      return
    fi
    local opts_var
    if [[ $lcmd == "startup_options" ]]; then
      opts_var="BAZEL_STARTUP_OPTIONS"
    else
      opts_var="BAZEL_COMMAND_${lcmd:u}_FLAGS"
    fi
    local -a raw_options
    if ! eval "raw_options=(\${(@f)$opts_var})"; then
      return
    fi

    local -a option_list
    for opt in $raw_options; do
      case $opt in
        --*"={"*)
          local lst="${${opt##*"={"}%"}"}"
          local opt="${opt%%=*}="
          option_list+=("${opt}:string:_values '' ${lst//,/ }") ;;
        --*=path)
          option_list+=("${opt%path}:path:_files") ;;
        --*=label)
          option_list+=("${opt%label}:target:_bazel_complete_target") ;;
        --*=*)
          option_list+=("${opt}:string:") ;;
        *)
          option_list+=("$opt") ;;
      esac
    done

    local -a cmd_args
    local cmd_type
    if eval "cmd_type=\${BAZEL_COMMAND_${lcmd:u}_ARGUMENT}" && [[ -n $cmd_type ]]; then
      case $cmd_type in
        label|label-*)
          cmd_args+=("*::${cmd_type}:_bazel_complete_target_${cmd_type//-/_}") ;;
        info-key)
          cmd_args+=('1::key:_bazel_info_key') ;;
        path)
          cmd_args+=('1::profile:_path_files') ;;
        "command|{"*"}")
          local lst=${${cmd_type#"command|{"}%"}"}
          cmd_args+=("1::topic:_bazel_help_topic -- ${lst//,/ }") ;;
      esac
    fi

    typeset -g "${_bazel_cmd_options}"="${(pj:|:)option_list[*]}"
    _store_cache BAZEL_${lcmd}_options ${_bazel_cmd_options}
    typeset -g "${_bazel_cmd_args}"="${(pj:|:)cmd_args[*]}"
    _store_cache BAZEL_${lcmd}_args ${_bazel_cmd_args}
  fi
}

_get_build_targets() {
  local pkg=$1
  local rule_re
  typeset -a completions
  case $target_type in
    test)
      rule_re=".*_test"
      ;;
    build)
      rule_re=".*"
      ;;
    bin)
      rule_re=".*_test|.*_binary"
      ;;
  esac
  completions=(${$(b query "kind(\"${rule_re}\", ${pkg}:all)" 2>/dev/null)##*:})
  if ( (( ${#completions} > 0 )) && [[ $target_type != run ]] ); then
    completions+=(all)
  fi
  echo ${completions[*]}
}

# Returns all packages that match $PREFIX.  PREFIX may start with //, in which
# case the workspace roots are searched.  Otherwise, they are completed based on
# PWD.
_get_build_packages() {
  local workspace pfx
  typeset -a package_roots paths final_paths
  workspace=$PWD
  package_roots=(${(ps.:.)BAZEL_COMPLETION_PACKAGE_PATH})
  package_roots=(${^package_roots//\%workspace\%/$workspace})
  if [[ "${(e)PREFIX}" == //* ]]; then
    pfx=${(e)PREFIX[2,-1]}
  else
    pfx=${(e)PREFIX}
  fi
  paths=(${^package_roots}/${pfx}*(/))
  for p in ${paths[*]}; do
    if [[ -f ${p}/BUILD || -f ${p}/BUILD.bazel ]]; then
      final_paths+=(${p##*/}:)
    fi
    final_paths+=(${p##*/}/)
  done
  echo ${final_paths[*]}
}

_package_remove_slash() {
  if [[ $KEYS == ':' && $LBUFFER == */ ]]; then
    LBUFFER=${LBUFFER[1,-2]}
  fi
}

# Completion function for BUILD targets, called by the completion system.
_bazel_complete_target() {
  local expl
  typeset -a packages targets
  if [[ "${(e)PREFIX}" != *:* ]]; then
    # There is no : in the prefix, completion can be either
    # a package or a target, if the cwd is a package itself.
    if [[ -f $PWD/BUILD || -f $PWD/BUILD.bazel ]]; then
      targets=($(_get_build_targets ""))
      _description build_target expl "BUILD target"
      compadd "${expl[@]}" -a targets
    fi
    packages=($(_get_build_packages))
    _description build_package expl "BUILD package"
    # Chop of the leading path segments from the prefix for display.
    compset -P '*/'
    compadd -R _package_remove_slash -S '' "${expl[@]}" -a packages
  else
    targets=($(_get_build_targets "${${(e)PREFIX}%:*}"))
    _description build_target expl "BUILD target"
    # Ignore the current prefix for the upcoming completion, since we only list
    # the names of the targets, not the full path.
    compset -P '*:'
    compadd "${expl[@]}" -a targets
  fi
}

_bazel_complete_target_label() {
  typeset -g target_type=build
  _bazel_complete_target
}

_bazel_complete_target_label_test() {
  typeset -g target_type=test
  _bazel_complete_target
}

_bazel_complete_target_label_bin() {
  typeset -g target_type=bin
  _bazel_complete_target
}

### Actual completion commands

_bazel() {
  _adapt_subcommand_offset
  if (( CURRENT - OFFSET > 0 )); then
    # Remember the subcommand name, stored globally so we can access it
    # from any subsequent function
    cmd=${words[OFFSET]//-/_}

    # Set the context for the subcommand.
    curcontext="${curcontext%:*:*}:bazel-$cmd:"
    _set_cache_policy

    # Narrow the range of words we are looking at to exclude cmd
    # name and any leading options
    (( CURRENT = CURRENT - OFFSET + 1 ))
    shift $((OFFSET - 1)) words
    # Run the completion for the subcommand
    _bazel_get_options $cmd
    _arguments : \
      ${(Pps:|:)_bazel_cmd_options} \
      ${(Pps:|:)_bazel_cmd_args}
  else
    _set_cache_policy
    # Start special handling for global options,
    # which can be retrieved by calling
    # $ bazel help startup_options
    _bazel_get_options startup_options
    _arguments : \
      ${(Pps:|:)_bazel_cmd_options} \
      "*:commands:_bazel_commands"
  fi
  return
}

_get_commands() {
  # bazel_cmd_list is a global (g) array (a)
  typeset -ga _bazel_cmd_list
  # Use `bazel help` instead of `bazel help completion` to get command
  # descriptions.
  if _bazel_cmd_list=("${(@f)$(b help | awk '
/Available commands/ { command=1; }
/  [-a-z]+[ \t]+.+/ { if (command) { printf "%s:", $1; for (i=2; i<=NF; i++) printf "%s ", $i; print "" } }
/^$/ { command=0; }')}"); then
    _store_cache BAZEL_commands _bazel_cmd_list
  fi
}

# Completion function for bazel subcommands, called by the completion system.
_bazel_commands() {
  if [[ ${#_bazel_cmd_list} == 0 ]]; then
    if _cache_invalid BAZEL_commands \
      || ! _bazel_safe_retrieve_cache BAZEL_commands _bazel_cmd_list; then
      _get_commands
    fi
  fi

  _describe -t bazel-commands 'Bazel command' _bazel_cmd_list
}

# Completion function for bazel help options, called by the completion system.
_bazel_help_topic() {
  if [[ ${#_bazel_cmd_list} == 0 ]]; then
    if _cache_invalid BAZEL_commands \
      || ! _bazel_safe_retrieve_cache BAZEL_commands _bazel_cmd_list; then
      _get_commands
    fi
  fi

  while [[ $# -gt 0 ]]; do
    if [[ $1 == -- ]]; then
      shift
      break
    fi
    shift
  done
  _bazel_help_list=($@)
  _bazel_help_list+=($_bazel_cmd_list)
  _describe -t bazel-help 'Help topic' _bazel_help_list
}

# Completion function for bazel info keys, called by the completion system.
_bazel_info_key() {
  if [[ ${#_bazel_info_keys_list} == 0 ]]; then
    if _cache_invalid BAZEL_info_keys \
      || ! _bazel_safe_retrieve_cache BAZEL_info_keys _bazel_info_keys_list; then
      typeset -ga _bazel_info_keys_list
      # Use `bazel help` instead of `bazel help completion` to get info-key
      # descriptions.
      if _bazel_info_keys_list=("${(@f)$(b help info-keys | awk '
  { printf "%s:", $1; for (i=2; i<=NF; i++) printf "%s ", $i; print "" }')}"); then
        _store_cache BAZEL_info_keys _bazel_info_keys_list
      fi
    fi
  fi
  _describe -t bazel-info 'Key' _bazel_info_keys_list
}
EOF
}
set -eu

onboarding () {
    if [ "$(uname -m)" = arm64 ]; then
        softwareupdate --install-rosetta --agree-to-license
    fi

    awsscratch
    bazelisk_setup

    cd "$MMS_HOME"
    ~/bin/bazel run //scripts/onboarding:onboarding
}
onboarding
