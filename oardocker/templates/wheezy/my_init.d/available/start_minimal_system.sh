#!/bin/sh
set -e

echo "Starting rsyslog..."
/etc/init.d/rsyslog restart

echo "Starting sshd..."
/etc/init.d/ssh restart
