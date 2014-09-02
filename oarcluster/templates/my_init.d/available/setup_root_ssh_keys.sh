#!/bin/sh
set -e

install -d -o root -g root -m 0700 /root/.ssh
install -o root -g root -m 0600 /home/docker/.ssh/authorized_keys /root/.ssh/authorized_keys
