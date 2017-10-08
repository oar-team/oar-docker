#!/bin/bash

# wait_pgsql --host server --user oar --password oar

echo_and_run() { echo "$@" ; $@ ; }

# slow
# systemd-analyze blame | grep resources -> 5.469s oardocker-resources.service
function create_resources_automatically() {
    while read node; do
        wait_ssh -h $node -p 22
        echo $node | oar_resources_init -y -x -
    done </var/lib/container/nodes
}


function create_resources_manually() {
    mem=$(grep -e "^MemTotal" /proc/meminfo | awk '{print $2}')
    mem=$((mem / 1024 / 1024 + 1))
    num_cpuset=$(grep -e "^processor\s\+:" /proc/cpuinfo | sort -u | wc -l)

    oarproperty -a cpu || true
    oarproperty -a core || true
    oarproperty -c -a host || true
    oarproperty -a mem || true

    cpu=1
    while read node; do
      for ((cpuset=0;cpuset<$num_cpuset; cpuset++)); do
        core=$((((cpu - 1) * num_cpuset) + cpuset + 1))
        echo_and_run oarnodesetting -a -h $node -p host=$node -p cpu=$cpu -p core=$core -p cpuset=$cpuset -p mem=$mem
      done
      cpu=$((cpu + 1))
    done </var/lib/container/nodes
}

# slower
# systemd-analyze blame | grep resources -> 5.469s oardocker-resources.service
# create_resources_automatically

# faster
# systemd-analyze blame | grep resources -> 2.448s oardocker-resources.service
create_resources_manually
