#!/bin/sh
set -e

echo "Starting rsyslog..."
/etc/init.d/rsyslog start
echo "Starting sshd..."
/etc/init.d/ssh start
