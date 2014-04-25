#!/bin/bash
set -e

mkdir -p /var/log/supervisor

touch /var/log/auth.log
touch /var/log/supervisor/oar-node.log
/sbin/rtail /var/log/auth.log /var/log/supervisor/oar-node.log
