#!/bin/sh
set -e

STAMP="/var/lib/container/stamps_oar_database_created"
## Clean
rm -f $STAMP

echo "Waiting postgresql to be available..."
wait_pgsql --host server

if setuser postgres psql -lqt | cut -d \| -f 1 | grep -w oar >/dev/null; then
    echo "OAR database already exists"
else
    /usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host server
fi

touch "$STAMP"
