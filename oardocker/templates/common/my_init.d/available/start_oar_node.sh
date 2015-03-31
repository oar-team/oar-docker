#!/bin/sh
set -e

echo "Starting oar-node..."
mkdir -p /var/run/sshd
chmod 0755 /var/run/sshd
/usr/sbin/sshd -f /etc/oar/sshd_config -D
