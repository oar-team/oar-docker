#!/bin/sh
set -e

mkdir -p /etc/skel/.ssh
rm -rf /etc/skel/.ssh/id_* /etc/skel/.ssh/authorized_keys

# Generate default ssh keys
echo "Generating new SSH keys"
ssh-keygen -t rsa -b 4096 -C "oardocker-sshkeys" -N "" -f /etc/skel/.ssh/id_rsa
cp /etc/skel/.ssh/id_rsa.pub /etc/skel/.ssh/authorized_keys

# Fix permissions
chmod 700 /etc/skel/.ssh
chmod 600 /etc/skel/.ssh/*

# Copy ssh keys to the docker user
rsync -ah --quiet --delete /etc/skel/.ssh/ /home/docker/.ssh
chown -R docker:docker /home/docker/.ssh

# Copy ssh keys to the root user
rsync -ah --quiet --delete /etc/skel/.ssh/ /root/.ssh
chown -R root:root /root/.ssh
