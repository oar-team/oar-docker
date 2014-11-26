#!/bin/sh
set -e

echo "Starting postgresql..."
/etc/init.d/postgresql restart

echo "Waiting postgresql to be available..."
wait_pgsql --host server

touch /var/lib/container/database_ready
