#!/bin/sh
set -e

users="user1 user2 user3"


for name in $users; do
    echo "Adding user $name..."
    useradd --user-group --no-create-home $name -s /bin/bash
    echo -n "$name:$name" | chpasswd
    usermod --append --groups sudo $name

    ## We also need to copy configuration files (vimrc, bashrc, tmux.conf..)
    cp -rT /home/docker /home/$name
    chown $name:$name -R /home/$name
done
