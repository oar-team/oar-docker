#!/bin/sh
set -e

USERS="user1 user2 user3 user4 user5"
USER_ID=1100

for NAME in $USERS; do
    USER_ID=$((USER_ID+1))
    echo "Adding user $NAME..."
    useradd --user-group $NAME -s /bin/bash --create-home -u $USER_ID
    echo -n "$NAME:$NAME" | chpasswd
    usermod --append --groups sudo $NAME
done
