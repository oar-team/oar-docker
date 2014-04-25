#!/bin/bash
set -e

wait_file() {
    echo "Waiting file $1"
    until test -f $1
    do
      sleep 1
      echo "."
    done
}

wait_file /var/log/auth.log
wait_file /var/log/supervisor/oar-node.log
/sbin/rtail /var/log/auth.log /var/log/supervisor/oar-node.log
