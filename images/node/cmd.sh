#!/bin/bash
set -e

/sbin/set_hostname_color.sh

mkdir -p /var/log/supervisor

touch /var/log/auth.log
touch /var/log/supervisor/oar-node.log
touch /var/log/auth.log

/sbin/rtail /var/log/auth.log /var/log/supervisor/oar-node.log /var/log/auth.log
