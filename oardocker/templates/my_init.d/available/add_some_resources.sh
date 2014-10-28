#!/bin/bash

echo_and_run() { echo "$@" ; $@ ; }


oarproperty -a cpu
oarproperty -a core
oarproperty -a thread

OLDIFS=$IFS

IFS=$'\n'
CPU=0
CORE=0
THREAD=0
cpu=
core=
thread=
for ((h=0;h<$NUM_NODES;h++)) do
  cpus=
  cores=
  threads=
  for l in $(< /proc/cpuinfo); do
    case $l in
    "processor"*)
      thread=${l#*: }
      threads[$thread]=$thread
    ;;
    "core id"*)
      core=${l#*: }
      cores[$core]=$core
    ;;
    "physical id"*)
      cpu=${l#*: }
      cpus[$cpu]=$cpu
    ;;
    esac
    if [ -n "$thread" -a -n "$core" -a -n "$cpu" ]; then
      echo_and_run oarnodesetting -a -h node$((h+1)) -p cpu=$((CPU + cpu)) -p core=$((CORE + core)) -p thread=$((THREAD + thread)) -p cpuset=$thread
      cpu=
      core=
      thread=
    fi
  done
  CPU=$((CPU + ${#cpus[*]}))
  CORE=$((CORE + ${#cores[*]}))
  THREAD=$((THREAD + ${#threads[*]}))
done
IFS=$OLDIFS
