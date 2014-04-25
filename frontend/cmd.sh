#!/bin/bash
set -e

mkdir -p /var/log/apache2/
touch /var/log/apache2/access.log
touch /var/log/apache2/error.log

/sbin/rtail /var/log/apache2/access.log /var/log/apache2/error.log
