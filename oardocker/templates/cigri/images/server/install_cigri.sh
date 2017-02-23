#!/bin/bash
set -e

# Install oar
/bin/bash /root/install_oar.sh $*

# Starting postgres
echo "Starting postgresql..."
/etc/init.d/postgresql restart

echo "Waiting postgresql to be available..."
sudo -u postgres wait_pgsql

# Cigri DB installation
cd /root
git clone https://github.com/oar-team/cigri.git
cd /root/cigri/database
./init_db.rb -d cigri3 -u cigri3 -p cigri3 -t psql -s ./psql_structure.sql

# Stopping postgres
echo "Starting postgresql..."
/etc/init.d/postgresql stop
