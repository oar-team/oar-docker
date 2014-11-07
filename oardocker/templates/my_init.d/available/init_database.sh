#!/bin/sh
set -e

file="/var/lib/container/database_ready"
while [ ! -f "$file" ]
do
    sleep 0.1
done

echo "Waiting postgresql to be available..."
wait_pgsql --host server

/usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host server

touch /var/lib/container/oar_database_ready
