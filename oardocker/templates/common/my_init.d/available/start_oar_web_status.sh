#!/bin/sh
set -e

echo "Starting http server..."
/etc/init.d/nginx start
/etc/init.d/php5-fpm start

/usr/bin/spawn-fcgi -n -s /var/run/oar-fcgi.sock -u oar -g oar -U www-data -G www-data -- /usr/sbin/fcgiwrap
