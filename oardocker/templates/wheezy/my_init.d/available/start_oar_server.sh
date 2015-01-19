#!/bin/sh
set -e

STAMP="/var/lib/container/stamps_oar_database_created"

echo "Waiting OAR database to be available..."
wait_pgsql --host server
wait_pgsql --host server --user oar --password oar

while [ ! -f "$STAMP" ]
do
    sleep 0.1
done

echo "Starting oar-server..."
/etc/init.d/oar-server restart
