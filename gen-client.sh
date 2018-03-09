#!/bin/bash

#
# You must configure this variables before using the script!!!
#

EASYRSA_PATH="/root/easy-rsa-3"
OPENVPNCLIENT_PATH="/root/openvpn/clients"
OPENVPN_PORT="1194"
OPENVPN_REMOTE="www.google.com"
TA_KEY_PATH="/root/openvpn/ta.key"

###########################################################################
# Don't modify anything down this block
##########################################################################

abort() {
        echo $1;
        exit 1;
}

username=$1

addtofile() {
        mkdir -p "$OPENVPNCLIENT_PATH/.tmp"
        echo $1 >> "$OPENVPNCLIENT_PATH/.tmp/${username}.ovpn"
}

## Init process
if [ -z "$username" ]
then
        abort "You must provide the name for the client"
fi

cd $EASYRSA_PATH
if [ -s ./easyrsa ]
then
        echo "Generating key for user ${username}"
        ./easyrsa gen-req $1 nopass
        ./easyrsa sign-req client $1
        echo "Done"
else
        abort "easyrsa script not found in path"
fi

echo "Preparing .ovpn file..."
addtofile "client"
addtofile "dev tun"
addtofile "proto udp"
addtofile "port $OPENVPN_PORT"
addtofile "remote $OPENVPN_REMOTE $OPENVPN_PORT udp"
addtofile "remote-cert-tls server"
addtofile "resolv-retry infinite"
addtofile "nobind"
addtofile "persist-key"
addtofile "persist-tun"
addtofile "comp-lzo"
addtofile "verb 3"


# Ensure we can connect securely to the server
echo "Adding security parameters to client configuration file"
addtofile "cipher AES-256-CBC"
addtofile "auth SHA512"
addtofile "tls-version-min 1.2"
addtofile "tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384"

# Adding ca certificate to ovpn client configuration file
echo "Adding ca certificate to ovpn client configuration file"
addtofile "<ca>" >> "$OPENVPNCLIENT_PATH"/.tmp/${username}.ovpn
cat "$EASYRSA_PATH"/pki/ca.crt | grep -A 100 "BEGIN CERTIFICATE" | grep -B 100 "END CERTIFICATE" >> "$OPENVPNCLIENT_PATH"/.tmp/${username}.ovpn
addtofile "</ca>"
echo "Done"

# Adding user certificate to ovpn client configuration file
echo "Adding user certificate to ovpn client configuration file"
addtofile "<cert>"
cat "$EASYRSA_PATH"/pki/issued/${username}.crt | grep -A 100 "BEGIN CERTIFICATE" | grep -B 100 "END CERTIFICATE" >> "$OPENVPNCLIENT_PATH"/.tmp/${username}.ovpn
addtofile "</cert>"
echo "Done"

# Adding user key to ovpn client configuration file
echo "Adding user key to ovpn client configuration file"
addtofile "<key>"
cat "$EASYRSA_PATH"/pki/private/${username}.key | grep -A 100 "BEGIN PRIVATE KEY" | grep -B 100 "END PRIVATE KEY" >> "$OPENVPNCLIENT_PATH"/.tmp/${username}.ovpn
addtofile "</key>"

# Adding ta file to ovpn client configuration file
echo "Adding tls-auth to ovpn client configuration file"
addtofile "key-direction 1"
addtofile "<tls-auth>"
cat "$TA_KEY_PATH" | grep -A 100 "BEGIN OpenVPN Static key V1" | grep -B 100 "END OpenVPN Static key V1" >> "$OPENVPNCLIENT_PATH"/.tmp/${username}.ovpn
addtofile "</tls-auth>"

mkdir -p "$OPENVPNCLIENT_PATH"/${username}
mv "$OPENVPNCLIENT_PATH"/.tmp/${username}.ovpn "$OPENVPNCLIENT_PATH"/${username}/${username}.ovpn
cd "$OPENVPNCLIENT_PATH"; tar -jcf ${username}.tar.bz2 ${username}/
echo "Done"

echo "
=========================================================================================

            Configurations are located in $OPENVPNCLIENT_PATH/${username}

    ---------------------------------------------------------------------------------
                       Download friendly version with:

            'scp root@`hostname -f`:$OPENVPNCLIENT_PATH/${username}.tar.bz2 .'

=========================================================================================
"

exit 0
