#!/bin/sh
set -e

echo "Starting oar-node..."
sleep 1
/etc/init.d/oar-node restart
