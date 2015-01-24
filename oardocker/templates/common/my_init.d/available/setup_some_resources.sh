#!/bin/bash

STAMP="/var/lib/container/stamps_oar_resources_initialized"

while [ ! -f "/var/lib/container/stamps_oar_database_created" ]
do
    sleep 0.1
done

if [ -f "$STAMP" ]; then
    echo "OAR resources already initialized"
else
    oar_resources_init /var/lib/container/nodes \
      -o /tmp/oar_resources_init.cmd \
      <<< "$(echo -e 'yes\nyes\n')"
    source /tmp/oar_resources_init.cmd
    touch $STAMP
fi
