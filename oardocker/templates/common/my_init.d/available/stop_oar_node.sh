#!/bin/sh
set -e


/etc/init.d/rsyslog stop

PID=`ps awux | grep sshd | grep -v grep | awk '{print $2}'`
kill -9 $PID
