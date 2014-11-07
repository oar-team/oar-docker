#!/bin/sh
set -e

file="/var/lib/container/oar_database_ready"
while [ ! -f "$file" ]
do
    sleep 0.1
done

echo "Waiting OAR database to be available..."
wait_pgsql --host server --user oar --password oar

echo "Starting oar-server..."
/etc/init.d/oar-server restart

