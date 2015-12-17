#!/bin/bash

set -e


AUTHORIZED_KEYS=/var/lib/oar/.ssh/authorized_keys
DIR=`dirname "$AUTHORIZED_KEYS"`

echo "Installing OAR ssh keys to $DIR"
mkdir -p "$DIR"
chmod 700 "$DIR"
cat /etc/skel/.ssh/authorized_keys >> "$AUTHORIZED_KEYS"
echo "environment=\"OAR_KEY=1\" $(cat $AUTHORIZED_KEYS)" > $AUTHORIZED_KEYS
cat /etc/skel/.ssh/id_rsa.pub > $DIR/id_rsa.pub
cat /etc/skel/.ssh/id_rsa > $DIR/id_rsa

echo "Host *
ForwardX11 no
StrictHostKeyChecking no
PasswordAuthentication no
AddressFamily inet
Compression yes
Protocol 2
" > $DIR/config

chmod 600 $DIR/id_rsa $DIR/id_rsa.pub $DIR/config
chown oar:oar -R "$DIR"
