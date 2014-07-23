#!/bin/sh
set -e

users="user1 user2 user3 toto"


for name in $users; do
    echo "Adding user $name..."
    useradd --user-group --no-create-home $name -s /bin/bash
    echo -n "$name:$name" | chpasswd
    usermod --append --groups sudo $name
    cp -rT /home/docker /home/$name
    chown $name:$name -R /home/$name
done
