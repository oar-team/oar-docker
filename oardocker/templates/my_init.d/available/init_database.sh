#!/bin/sh
set -e

echo "Waiting postgresql to be available..."
wait_pgsql --host server


/usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host server
