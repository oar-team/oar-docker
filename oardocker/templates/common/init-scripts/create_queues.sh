#!/bin/bash

# wait_pgsql --host server --user oar --password oar

echo_and_run() { echo "$@" ; $@ ; }

function create_queues() {
    q=1
    cd /usr/local/lib/oar/schedulers
    for s in * ; do
        echo_and_run oarnotify --add-queue Q$q,$((2 + q++)),$s
    done
}

create_queues
