#!/bin/bash
set -e

/sbin/set_hostname_color.sh

mkdir -p /var/log/apache2/
touch /var/log/apache2/access.log
touch /var/log/apache2/error.log
touch /var/log/auth.log

/sbin/rtail /var/log/apache2/access.log /var/log/apache2/error.log /var/log/auth.log

