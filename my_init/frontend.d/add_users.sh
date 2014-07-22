#!/bin/bash
set -e

users=( "user1" "user2" "user3" )


for name in "${users[@]}"; do
    echo "Adding user $name..."
    useradd -m $name -s /bin/bash
    echo -n "$name:$name" | chpasswd
    usermod -a -G sudo $name
    install -d -o $name -g $name -m 0700 /home/$name/.ssh
    install -o $name -g $name -m 0600 /home/docker/.ssh/authorized_keys /home/$name/.ssh/authorized_keys
done
