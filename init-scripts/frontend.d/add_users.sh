#!/bin/bash
set -e

users=( "user1" "user2" "user3" "toto")


for name in "${users[@]}"; do
    echo "Adding user $name..."
    useradd -m $name -s /bin/bash
    echo -n "$name:$name" | chpasswd
    usermod -a -G sudo $name
done
