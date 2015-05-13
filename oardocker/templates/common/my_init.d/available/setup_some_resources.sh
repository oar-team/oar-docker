#!/bin/bash

STAMP="/var/lib/container/stamps_oar_resources_initialized"

while [ ! -f "/var/lib/container/stamps_oar_database_created" ]
do
    sleep 0.1
done

if [ -f "$STAMP" ]; then
    echo "OAR resources already initialized"
else
    DIR=`TMPDIR=/tmp mktemp -d --tmpdir ${tmpdir}_XXX`
    NODE_NAME_FILE="$DIR/current_node"
    NODE_CMD_FILE="$DIR/oar_resources_init.cmd"

    while read node; do
        wait_ssh -h $node -p 22
        echo "$node" > "$NODE_FILE"
        oar_resources_init "$NODE_FILE" -o "$NODE_CMD_FILE" <<< "$(echo -e 'yes\nyes\n')"
        source "$NODE_CMD_FILE"
    done </var/lib/container/nodes

    touch $STAMP
fi
