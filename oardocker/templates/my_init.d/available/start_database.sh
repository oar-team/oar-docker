#!/bin/sh
set -e

echo "Starting postgresql..."
/etc/init.d/postgresql restart

touch /var/lib/container/database_ready
