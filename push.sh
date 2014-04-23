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

$DOCKER push oarcluster/base
$DOCKER push oarcluster/dnsmasq

NODES=("frontend" "node" "server")
for image in ${NODES[@]}; do
    $DOCKER push oarcluster/$image
done
