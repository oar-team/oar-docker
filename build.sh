#!/bin/bash
set -o errexit

DOCKER=${DOCKER:-docker}
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

$DOCKER build --rm -t oarcluster/base $BASEDIR/base/
$DOCKER build --rm -t oarcluster/dnsmasq $BASEDIR/dnsmasq/

NODES=("frontend" "node" "server")
for image in "${NODES[@]}"; do
    echo "$VERSION" > $BASEDIR/$image/version.txt
    $DOCKER build --rm -t oarcluster/$image:${VERSION} $BASEDIR/$image/
    $DOCKER tag oarcluster/$image:${VERSION} oarcluster/$image:latest
done
$DOCKER images | grep "<none>" | awk '{print $3}' | xargs -I {} $DOCKER rmi -f {}
