PUBSSHKEY="/Users/udita.bose/.ssh/github_rsa.pub" # can be link to ssh public key e.g.  ~/.ssh/id_rsa.pub
PUBKEY=pub.pkcs8
FILE_TO_ENCRYPT=$(echo "Test :D")
ENCRYPTED_FILE=test.txt.encrypted

set -x
ssh-keygen -e -f "${PUBSSHKEY}" -m PKCS8 > "${PUBKEY}"
echo "${FILE_TO_ENCRYPT}" | openssl pkeyutl -encrypt -pubin -inkey "${PUBKEY}" -out "${ENCRYPTED_FILE}"
