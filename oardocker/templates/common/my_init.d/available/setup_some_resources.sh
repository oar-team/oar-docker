#!/bin/bash

STAMP="/var/lib/container/stamps_oar_resources_initialized"

wait_pgsql --host server --user oar --password oar

NODE_CMD_FILE="/tmp/_oar_resources_init_current_node"
NODE_HOST_FILE="/tmp/_oar_resources_init_hosts_file"
while read node; do
    wait_ssh -h $node -p 22
    # echo $node | oar_resources_init -o -y -x
    echo $node > "$NODE_HOST_FILE"
    chown oar:oar "$NODE_HOST_FILE"
    oar_resources_init -x "$NODE_HOST_FILE" <<< "$(echo -e 'yes\nyes\n')"
done </var/lib/container/nodes

touch $STAMP
