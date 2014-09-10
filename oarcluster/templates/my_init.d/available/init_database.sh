#!/bin/sh
set -e

# Create OAR database
until nc -z services 5432; do
    echo "Waiting database to be available"
    sleep 1
done

/usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host services
/usr/local/sbin/oarproperty -a core
/usr/local/sbin/oarproperty -a cpu
