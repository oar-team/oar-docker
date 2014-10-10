#!/bin/bash

echo_and_run() { echo "$@" ; $@ ; }


/usr/local/sbin/oarproperty -a cpu
/usr/local/sbin/oarproperty -a core
/usr/local/sbin/oarproperty -a thread

NODE_COUNT=$NUM_NODES;
CPU_COUNT=$(grep "^physical id" /proc/cpuinfo | sort -u | wc -l)
CORE_COUNT=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)
CPUSET=$(grep -e "^processor\s\+:" /proc/cpuinfo | sort -u | wc -l)
THREAD_COUNT=$((CPUSET/CORE_COUNT))
cpu=0
core=0
thread=0
for ((node=1;node<=$NODE_COUNT; node++)); do
  hostname="node${node}"
  while [ $cpu -lt $((CPU_COUNT * node)) ]; do
    while [ $core -lt $((CORE_COUNT * (cpu+1))) ]; do
      while [ $thread -lt $((THREAD_COUNT * (core+1))) ]; do
        echo_and_run oarnodesetting -a -h $hostname -p cpu=$cpu -p core=$core -p thread=$thread -p cpuset=$((thread % $CPUSET))
        thread=$((thread+1))
      done
      core=$((core+1))
    done
    cpu=$((cpu+1))
  done
done
