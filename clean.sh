#!/bin/bash
WORKDIR=/tmp/oarcluster/
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

echo "Cleanup old containers"

CONTAINERS=`docker ps -a | grep oarcluster | awk '{print $1}' | tr '\n' ' '`
CONTAINERS=($CONTAINERS)
for container in "${CONTAINERS[@]}"; do
    echo "$(docker kill $container) --> Stopped"
done
for container in "${CONTAINERS[@]}"; do
    echo "$(docker rm $container) --> Removed"
done
if [ -d "$WORKDIR" ]; then
    rm -fr "$WORKDIR"
fi

echo "OK"
