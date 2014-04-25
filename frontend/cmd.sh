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

wait_file /var/log/apache2/access.log
wait_file /var/log/apache2/error.log

/sbin/rtail /var/log/apache2/access.log /var/log/apache2/error.log
