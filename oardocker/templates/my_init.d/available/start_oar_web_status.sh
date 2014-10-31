#!/bin/sh
set -e

echo "Starting nginx..."
/etc/init.d/nginx start
echo "Starting php5-fpm..."
/etc/init.d/php5-fpm start
echo "Starting fcgiwrap..."
/etc/init.d/fcgiwrap start
