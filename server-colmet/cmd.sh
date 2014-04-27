#!/bin/bash
set -e

/usr/local/sbin/oar-server

echo_and_run() { echo "$@" ; "$@" ; }

core=0
for i in `seq 1 $NUM_NODES`; do
  hostname="node${i}"
  echo_and_run oarnodesetting -a -h $hostname -p cpu=$(expr $i - 1) -p core="$(expr $core + 0)" -p cpuset=0
  echo_and_run oarnodesetting -a -h $hostname -p cpu=$i -p core="$(expr $core + 1)" -p cpuset=0
  core=$(expr $core + 2)
done

touch /var/log/oar.log
touch /var/log/auth.log
touch /var/log/supervisor/colmet-server.log

/sbin/rtail /var/log/auth.log /var/log/oar.log /var/log/supervisor/colmet-server.log
