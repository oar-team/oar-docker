#!/bin/bash

echo > /var/log/oar.log

function stop_server {
    if [ `ps --no-headers -o comm 1` = "systemd" ]; then
        systemctl stop oar-server
    else
        source /etc/init.d/oar-server stop
    fi
}

trap 'stop_server' INT TERM EXIT

if [ `ps --no-headers -o comm 1` = "systemd" ]; then
    systemctl start oar-server
else
    source /etc/init.d/oar-server start
fi

tail -F -n 0 /var/log/oar.log
