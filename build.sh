#!/bin/bash
set -o errexit

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

docker build --rm -t oarcluster/base $BASEDIR/base/
docker build --rm -t oarcluster/dnsmasq $BASEDIR/dnsmasq/

NODES=("frontend" "node" "server")
for image in "${NODES[@]}"; do
    docker build --rm -t oarcluster/$image:${VERSION} $BASEDIR/$image/
    docker tag oarcluster/$image:${VERSION} oarcluster/$image:latest
done
docker images | grep "<none>" | awk '{print $3}' | xargs -I {} docker rmi -f {}
