#!/bin/bash
set -e

touch /var/log/oar.log
touch /var/log/auth.log

/sbin/rtail /var/log/auth.log /var/log/oar.log
