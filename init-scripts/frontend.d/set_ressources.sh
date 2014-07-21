#!/bin/bash
set -e
echo_and_run() { echo "$@" ; $@ ; }

NUM_NODES=3
NUM_NODECPU=2
NUM_CPUCORE=2
NUM_CPUSET=$(grep -e "^processor\s\+:" /proc/cpuinfo | wc -l)
core=0
cpu=0
for ((i=0;i< $NUM_NODECPU; i++)); do
  hostname="node${i}"
  while [ $cpu -lt $((NUM_NODECPU * (i+1))) ]; do
    while [ $core -lt $((NUM_CPUCORE * (cpu+1))) ]; do
      echo_and_run oarnodesetting -a -h $hostname -p cpu=$cpu -p core=$core -p cpuset=$((core % $NUM_CPUSET))
      core=$((core+1))
    done
    cpu=$((cpu+1))
  done
done
