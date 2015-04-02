#!/bin/sh
set -e

echo "Starting rsyslog..."
/etc/init.d/rsyslog restart

echo "Starting oar-node..."
mkdir -p /var/run/sshd
chmod 0755 /var/run/sshd
# Allow to connect from normal ssh port (instead of running two sshd processes)
socat TCP-LISTEN:22,fork,reuseaddr TCP:localhost:6667 &
# Allow all users (for debug)
sed -i "s/AllowUsers oar//g" /etc/oar/sshd_config
sed -i "s/PermitRootLogin no/PermitRootLogin yes/g" /etc/oar/sshd_config
/usr/sbin/sshd -f /etc/oar/sshd_config -D
