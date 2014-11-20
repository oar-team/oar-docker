#!/bin/sh
set -e

file="/var/lib/container/database_ready"
while [ ! -f "$file" ]
do
    sleep 0.1
done

/usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host server

echo "Waiting OAR database to be available..."
wait_pgsql --host server --user oar --password oar

touch /var/lib/container/oar_database_ready
