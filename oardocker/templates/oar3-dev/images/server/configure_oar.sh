#!/bin/bash
set -e

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

echo "Set some links for OAR3"
ln -s /usr/local/bin/oar3-appendice-proxy /usr/local/lib/oar/oar3-appendice-proxy
ln -s /usr/local/bin/oar3-bipbip-commander /usr/local/lib/oar/oar3-bipbip-commander
ln -s /usr/local/bin/oar3-sarko /usr/local/lib/oar/oar3-sarko
ln -s /usr/local/bin/oar3-finaud /usr/local/lib/oar/oar3-finaud
ln -s /usr/local/bin/oar3-leon /usr/local/lib/oar/oar3-leon
ln -s /usr/local/bin/oar3-node-change-state /usr/local/lib/oar/oar3-node-change-state
ln -s /usr/local/bin/oar3-bipbip /usr/local/lib/oar/oar3-bipbip

echo "Set various things for OAR3"
ln -s /usr/local/bin/kamelot /usr/local/lib/oar/schedulers/kamelot
sed -i s/#HIERARCHY_LABELS/HIERARCHY_LABELS/g /etc/oar/oar.conf
echo 'META_SCHED_CMD="/usr/local/bin/kao"' >> /etc/oar/oar.conf
