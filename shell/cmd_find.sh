#!/usr/bin/env zsh -l

version () {
  echo "$1" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

if [ $(version $1) -ge $(version "1.0.2") ]; then
    echo "Version is up to date"
else
    echo "nope"
fi
# IFS=' '

# delimiter=' '
# echo "openssl : $defssl"
# echo "${defssl%%"$delimiter"*}"
# echo ${defssl#*"$delimiter"}
#
#
# delimiter=' '
# echo "openssl : $defssl"
# echo "${defssl%%"$delimiter"*}"
# echo ${defssl#*"$delimiter"}
# # if [ ]

ssl_details() {
    delimiter=' '
    ssl_det="$1"
    local details=()
    echo "${ssl_det%%"$delimiter"*}"
    details+="${ssl_det%%"$delimiter"*}"
    ssl_det="${ssl_det#*"$delimiter"}"
    echo "${ssl_det}"
    echo "${ssl_det%%"$delimiter"*}"
    details+="${ssl_det%%"$delimiter"*}"
    echo "details ${details[@]}"
    # echo "${details[@]}"
    details
}

defssl=$(openssl version)
local dets=$(ssl_details "$defssl")
echo "${dets[@]}"

defssl=$(/usr/local/opt/openssl/bin/openssl version)
