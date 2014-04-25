#!/bin/bash
set -o errexit

DOCKER=${DOCKER:-docker}
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

fail() {
    echo $@ 1>&2
    exit 1
}

$DOCKER 2> /dev/null || fail "error: Docker ($DOCKER) executable no found. Make sure Docker is installed and/or use the DOCKER variable to set Docker executable."

$DOCKER build --rm -t oarcluster/dnsmasq $BASEDIR/dnsmasq/

NODES=("frontend" "node" "node-colmet" "server")
for image in "${NODES[@]}"; do
    echo "$VERSION" > $BASEDIR/$image/version.txt
    $DOCKER build --rm -t oarcluster/$image:${VERSION} $BASEDIR/$image/
    $DOCKER tag oarcluster/$image:${VERSION} oarcluster/$image:latest
done
$DOCKER images | grep "<none>" | awk '{print $3}' | xargs -I {} $DOCKER rmi -f {}
