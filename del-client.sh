#!/bin/bash

## Remember to adjust these variables before running the script!!!

EASYRSA_PATH="/root/easy-rsa-3"
OPENVPNSSL_PATH="/root/openvpn"

#############################################################
## Don't modify anything starting here
#############################################################

username=$1

if [ -z "$username" ]
then
        echo "You must provide the name for the client"
        exit 1
fi

if [ -s ./easyrsa ]
then
        echo "Revoking cert for user ${username}"
        ./easyrsa revoke "$username"
        ./easyrsa gen-crl
        cp "$EASYRSA_PATH"/pki/crl.pem "$OPENVPNSSL_PATH"/crl.pem
        echo "Done"
else
        abort "easyrsa script not found in path"
fi
