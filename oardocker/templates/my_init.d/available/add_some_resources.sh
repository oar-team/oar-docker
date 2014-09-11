#!/bin/bash

echo_and_run() { echo "$@" ; $@ ; }


NUM_NODECPU=$(grep "^physical id" /proc/cpuinfo | sort -u | wc -l)
NUM_CPUCORE=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)
NUM_CPUSET=$(grep -e "^processor\s\+:" /proc/cpuinfo | sort -u | wc -l)
core=0
cpu=0
for ((node=1;node<=$NUM_NODES; node++)); do
  hostname="node${node}"
  while [ $cpu -lt $((NUM_NODECPU * node)) ]; do
    while [ $core -lt $((NUM_CPUCORE * (cpu+1))) ]; do
      echo_and_run oarnodesetting -a -h $hostname -p cpu=$cpu -p core=$core -p cpuset=$((core % $NUM_CPUSET))
      core=$((core+1))
    done
    cpu=$((cpu+1))
  done
done
