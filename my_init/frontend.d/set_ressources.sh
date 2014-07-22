#!/bin/bash
set -e
echo_and_run() { echo "$@" ; $@ ; }

while ! oarnodes --sql "false" 2> /dev/null; do
  sleep 1
done
 
NUM_NODES=4
NUM_NODECPU=2
NUM_CPUCORE=2
NUM_CPUSET=$(grep -e "^processor\s\+:" /proc/cpuinfo | wc -l)
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
