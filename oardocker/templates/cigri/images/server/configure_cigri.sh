#!/bin/bash
set -e

# Cigri DB installation
cd /root
git clone https://github.com/oar-team/cigri.git
cd /root/cigri/database
./init_db.rb -d cigri3 -u cigri3 -p cigri3 -t psql -s ./psql_structure.sql

# Oar property "cluster" creation
oarproperty -c -a cluster

