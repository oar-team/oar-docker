#!/bin/sh
set -e

users="user1 user2 user3 toto"


for name in $users; do
    echo "Adding user $name..."
    useradd --user-group --no-create-home $name -s /bin/bash
    echo -n "$name:$name" | chpasswd
    usermod --append --groups sudo $name
    # install -d -o $name -g $name -m 0700 /home/$name/.ssh
    # install -o $name -g $name -m 0600 /home/docker/.ssh/authorized_keys /home/$name/.ssh/authorized_keys

    ## It may be easier ? We need also copy configuration files (vimrc, bashrc, tmux.conf..)
    cp -rT /home/docker /home/$name
    chown $name:$name -R /home/$name
done
