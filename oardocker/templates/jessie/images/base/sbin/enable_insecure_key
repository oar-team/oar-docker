#!/bin/bash
set -e

function add_insecure_keys() {
	AUTHORIZED_KEYS=$1
	USER=$2
	if [[ -e "$AUTHORIZED_KEYS" ]] && grep -q oardocker-docker-insecure-key "$AUTHORIZED_KEYS"; then
		echo "Insecure key has already been added to $AUTHORIZED_KEYS."
	else
		DIR=`dirname "$AUTHORIZED_KEYS"`
		echo "Creating directory $DIR..."
		mkdir -p "$DIR"
		chmod 700 "$DIR"
		echo "Editing $AUTHORIZED_KEYS..."
		cat /etc/skel/.ssh/authorized_keys >> "$AUTHORIZED_KEYS"
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
		chown $USER:$USER -R "$DIR"
		echo "Success: insecure key has been added to $DIR"
	fi
}

if id -u oar >/dev/null 2>&1; then
    AUTHORIZED_KEYS_OAR=/var/lib/oar/.ssh/authorized_keys
    add_insecure_keys $AUTHORIZED_KEYS_OAR oar
    # oarsh need OAR_KEY env varibale to be set
    echo "environment=\"OAR_KEY=1\" $(cat $AUTHORIZED_KEYS_OAR)" > $AUTHORIZED_KEYS_OAR
fi

echo "

    +------------------------------------------------------------------------------+
    | Insecure SSH key installed                                                   |
    |                                                                              |
    | DO NOT expose sshd port on the Internet unless you know what you are doing!  |
    +------------------------------------------------------------------------------+

"
cat /root/.ssh/id_rsa
echo ""
echo ""
