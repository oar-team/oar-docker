#!/bin/bash

STAMP="/var/lib/container/stamps_oar_resources_initialized"

wait_pgsql --host server --user oar --password oar

while read node; do
    wait_ssh -h $node -p 22
    echo $node | oar_resources_init -y - -x
done </var/lib/container/nodes

touch $STAMP
