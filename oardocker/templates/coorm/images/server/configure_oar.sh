#!/bin/bash
set -e

ln -s /usr/local/bin/kamelot /usr/local/lib/oar/schedulers/kamelot

sed -i s/#HIERARCHY_LABELS/HIERARCHY_LABELS/g /etc/oar/oar.conf

echo "Starting postgresql..."
/etc/init.d/postgresql restart

echo "Waiting postgresql to be available..."
sudo -u postgres wait_pgsql

echo "Enable kamelot scheduler"
setuser postgres psql -d oar -c "update queues set scheduler_policy='kamelot';"

echo "Remove admission rules #15"
setuser postgres psql -d oar -c "delete from admission_rules where id='15';"

echo "Stopping postgresql..."
/etc/init.d/postgresql stop
