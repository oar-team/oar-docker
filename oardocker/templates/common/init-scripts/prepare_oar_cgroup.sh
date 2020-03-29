#!/bin/bash
# This script prepopulates OAR cgroup directory hierarchy, as used in the
# job_resource_manager_cgroups.pl script, in order to have nodes use different
# subdirectories and avoid conflitcs due to having all nodes actually running on
# the same host machine

OS_CGROUPS_PATH="/sys/fs/cgroup"

if [ "$1" = "init" ]; then
    for cg in $OS_CGROUPS_PATH/*; do
        [ -d $cg ] && mkdir -p $cg/oardocker/$HOSTNAME
    done
    cat $OS_CGROUPS_PATH/cpuset/cpuset.cpus > $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.cpus
    cat $OS_CGROUPS_PATH/cpuset/cpuset.mems > $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.mems
    /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.cpu_exclusive
    /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/notify_on_release
    /bin/echo 1000 > $OS_CGROUPS_PATH/blkio/oardocker/blkio.weight
    cat $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.cpus > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/cpuset.cpus
    cat $OS_CGROUPS_PATH/cpuset/oardocker/cpuset.mems > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/cpuset.mems
    /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/cpuset.cpu_exclusive
    /bin/echo 0 > $OS_CGROUPS_PATH/cpuset/oardocker/$HOSTNAME/notify_on_release
    /bin/echo 1000 > $OS_CGROUPS_PATH/blkio/oardocker/$HOSTNAME/blkio.weight
elif [ "$1" = "clean" ]; then
    if [ "$HOSTNAME" = "node1" ]; then
        for cg in $OS_CGROUPS_PATH/cpuset/oardocker $OS_CGROUPS_PATH/*/oardocker; do
            echo "kill all cgroup tasks"
            while read task; do
                echo "kill -9 $task"
                kill -9 $task
            done < <(find $cg -name tasks -exec cat {} \;)
            wait
            echo "Wipe all cgroup content"
            find $cg -depth -type d -exec rmdir {} \;
        done
        echo "Cgroup is cleanded!"
    fi
fi

exit 0
