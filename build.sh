#!/bin/bash
set -o errexit

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

docker build -t oarcluster/base $BASEDIR/base/
docker build -t oarcluster/dnsmasq $BASEDIR/dnsmasq/

NODES=("frontend" "node" "server")
for image in "${NODES[@]}"; do
    docker build --rm -t oarcluster/$image:${VERSION} $BASEDIR/$image/
    docker tag oarcluster/$image:${VERSION} oarcluster/$image:latest
done
