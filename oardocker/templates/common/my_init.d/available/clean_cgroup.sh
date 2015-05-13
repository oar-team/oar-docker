#!/bin/bash
# This script clean OAR cgroup directory

set -x

if [ "$HOSTNAME" = "node1" ]; then
    CGROOT="/sys/fs/cgroup/cpuset/oardocker/"

    if ! [ -d $CGROOT ]; then
      echo "No such directory: $CGROOT"
      exit 0;
    fi

    echo "kill all cgroup tasks"
    while read task; do
        echo "kill -9 $task"
        kill -9 $task
    done < <(find $CGROOT -name tasks -exec cat {} \;)

    wait
    echo "Wipe all cgroup content"
    find $CGROOT -depth -type d -exec rmdir {} \;

    echo "Cgroup is cleanded!"
fi

exit 0
