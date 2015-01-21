#!/bin/sh
set -e

echo "Stopping rsyslog..."
/etc/init.d/rsyslog stop

echo "Stopping sshd..."
/etc/init.d/ssh stop
