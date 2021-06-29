#!/usr/bin/env bash

TEST_DECRYPT_DATA="op8q1YbwdoGH3RmR7CeSgwXji2bV12LS7Rv6bQhFGZcLmcYYm+WwfCOaz4BMShxG4LlEyqedbIydafyvEhj366spwiinm4aQgXJyhAzGvTo5s2+URN2kEPc1tq2LTHMkktX2/SI3heQGkI8lA+cbrVY/fFBwEobKKjt5FgcO/piXvu4jn02CIwrM1pg7Ei3Y8Ru0LclM+wdMS6OHCq9u7rNbDDDGTJtQx9cKKa73L1nkow/6kE4LW9mqea8iB+oy4JUv2s7gP1H+eSDOrcIFhcxATM20cJjHWJEzQpN2YMZYBIvjpYz9cTL1P7PuXqUxo1dC60Bs0IXpgymCb+NjaA=="

RSA_PRIVATE_KEY="/Users/udita.bose/mms/server/scripts/nds/nds.ssh.private.pem"
export PATH="/usr/local/opt/openssl/bin:$PATH"
openssl_test_command="openssl pkeyutl -decrypt -inkey $RSA_PRIVATE_KEY -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256"


# BASE64_DATA=$(echo -n $TEST_DECRYPT_DATA | base64 --decode)
# echo "$BASE64_DATA"
# echo "--------"
echo -n $TEST_DECRYPT_DATA | base64 --decode | $openssl_test_command
RESULT="$?"
# openssl pkeyutl -decrypt -inkey $RSA_PRIVATE_KEY -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256
echo ""
if [ $RESULT -ne 0 ]; then
    echo "Sorry!!!"
else
    echo "Voila!"
fi
echo "--------"
# if ! $openssl_test_command; then
#     echo "lala here---"
#     if [ -d /usr/local/opt/openssl/bin ]; then
#         export PATH="/usr/local/opt/openssl/bin:$PATH"
#         echo "me here---"
#         if ! $openssl_test_command; then
#             echo "me here"
#             (>&2 echo "Your openssl is still too old, try running brew upgrade openssl")
#             exit 1
#         fi
#     else
#         echo "why me here"
#         (>&2 echo "Please run brew install openssl and try again")
#         exit 1
#     fi
# fi
# echo "me here!"
# set -e
