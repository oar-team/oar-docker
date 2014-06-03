#!/bin/bash

DOCKER=${DOCKER:-docker}
WORKDIR=/tmp/oarcluster/
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

fail() {
    echo $@ 1>&2
    exit 1
}

$DOCKER 2> /dev/null || fail "error: Docker ($DOCKER) executable no found. Make sure Docker is installed and/or use the DOCKER variable to set Docker executable."

echo "Cleanup old containers"

CONTAINERS2STOP=`$DOCKER ps -a | grep oarcluster_nfs_server | awk '{print $1}' | tr '\n' ' '`
CONTAINERS2STOP=($CONTAINERS2STOP)
for container in "${CONTAINERS2STOP[@]}"; do
    echo "$($DOCKER stop $container) --> Stopped"
done
CONTAINERS=`$DOCKER ps -a | grep oarcluster | awk '{print $1}' | tr '\n' ' '`
CONTAINERS=($CONTAINERS)
for container in "${CONTAINERS[@]}"; do
    echo "$($DOCKER kill $container) --> Killed"
done
for container in "${CONTAINERS[@]}"; do
    echo "$($DOCKER rm $container) --> Removed"
done
if [ -d "$WORKDIR" ]; then
    rm -fr "$WORKDIR"
fi

echo "OK"
