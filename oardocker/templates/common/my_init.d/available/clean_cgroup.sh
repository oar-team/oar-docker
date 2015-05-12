#!/bin/bash
# This script clean OAR cgroup directory


if [ "$HOSTNAME" = "node1" ]; then
    CGROOT="/sys/fs/cgroup/cpuset/oardocker/"

    if ! [ -d $CGROOT ]; then
      echo "No such directory: $CGROOT"
      exit 0;
    fi

    find $CGROOT -name tasks -exec grep -H -o "[[:digit:]]\+" {} \;
    find $CGROOT -name tasks -exec cat {} \; | xargs -n 1 kill -9
    find $CGROOT -depth -type d -exec rmdir {} \;
fi
