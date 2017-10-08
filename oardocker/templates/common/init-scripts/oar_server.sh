#!/bin/bash

echo > /var/log/oar.log

function stop_server {
    source /etc/init.d/oar-server stop
}

trap 'stop_server' INT TERM EXIT

source /etc/init.d/oar-server start

tail -F -n 0 /var/log/oar.log
