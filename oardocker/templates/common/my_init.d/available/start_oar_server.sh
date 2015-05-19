#!/bin/sh
set -e

echo "Waiting OAR database to be available..."
wait_pgsql --host server --user oar --password oar

echo "Starting oar-server..."
/etc/init.d/oar-server restart
