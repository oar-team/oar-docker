#!/bin/bash
set -o errexit

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

echo "Cleanup old containers"

CONTAINERS=`docker ps | grep oarcluster | awk '{print $1}' | tr '\n' ' '`
CONTAINERS=($CONTAINERS)
for container in "${CONTAINERS[@]}"; do
    docker kill "$container"
    docker rm "$container"
done

echo "OK"
