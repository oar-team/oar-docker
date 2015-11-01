#!/bin/sh
set -e

USERS="user1 user2 user3"
USER_ID=1100

for NAME in $USERS; do
    USER_ID=$((USER_ID+1))
    echo "Adding user $NAME..."
    useradd --user-group $NAME -s /bin/bash --no-create-home -u $USER_ID
    echo -n "$NAME:$NAME" | chpasswd
    usermod --append --groups sudo $NAME

    if [ "$HOSTNAME" = "frontend" ]; then
        ## We also need to copy configuration files (vimrc, bashrc, tmux.conf..)
        echo "Creating /home/$NAME"
        cp -rT /etc/skel /home/$NAME
        chown $NAME:$NAME -R /home/$NAME
    fi
done
