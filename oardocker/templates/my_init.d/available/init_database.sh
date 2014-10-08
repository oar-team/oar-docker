#!/bin/sh
set -e

# Create OAR database
echo -n "Waiting database to be available"
until nc -z server 5432; do
    sleep 1
    echo -n "."
done
echo


/usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host server
/usr/local/sbin/oarproperty -a core
/usr/local/sbin/oarproperty -a cpu
