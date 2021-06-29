#!/usr/bin/env zsh -l

source log.sh

# The have a gpg installed and on the path
if which gpg; then
  _log_success "gpg is installed"
else
  _log_warn "gpg not installed"
fi


# They have a gpg key
if gpg --list-secret-keys 'mongodb.com'; then
  _log_success "found gpg key for mongodb"
else
  _log_warn "could not find gpg key for mongodb"
fi

# Their key is associated with the email address they'll be using in Github
echo -n "username: "
read -r username
if gpg --list-secret-keys "${username}@mongodb.com"; then
  _log_success "found gpg key for ${username}"
else
  _log_warn "could not find gpg key for ${username}"
fi

# gpg can sign a temporary text file
TMPFILE=$(mktemp)
echo "Hey, this is a test file \n" >> "$TMPFILE"

if cat "$TMPFILE" | gpg --clear-sign --dry-run; then
  _log_success "can sign a text file"
else
  _log_warn "could not find gpg key for ${username}"
fi

# git commit signing config is setup (set to always sign and has present key selected)
signkey=$(git config  --get user.signingkey)
if gpg --list-secret-keys "${signkey}@mongodb.com"; then
  _log_success "git has a good gpg key"
else
  _log_warn "git does not has a good gpg key"
fi

signstatus=$(git config --global commit.gpgsign)
echo $signstatus

# git can sign a commit
branch="gpp-doctor-${username}"
git checkout -b "${branch}"
git commit --allow-empty --gpg-sign -m "test gpg"

# github sees a commit from them as verified
signedcommit=$(git --no-pager log -n 1 --oneline --show-signature | grep $signkey | wc -l | sed 's/ *$//g')

set -e
if [ "$signedcommit" -eq '1' ]; then
  _log_success "signed commit with key"
else
  _log_warn "can't sign a commit"
fi
set +e


git checkout master
git branch -d "${branch}"
