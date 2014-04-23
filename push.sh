#!/bin/bash
set -o errexit

DOCKER=${DOCKER:-docker}
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

$DOCKER push oarcluster/base
$DOCKER push oarcluster/dnsmasq

NODES=("frontend" "node" "server")
for image in ${NODES[@]}; do
    $DOCKER push oarcluster/$image
done
