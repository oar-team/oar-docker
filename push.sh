#!/bin/bash
set -o errexit

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

docker push oarcluster/base
docker push oarcluster/dnsmasq

NODES=("frontend" "node" "server")
for image in ${NODES[@]}; do
    docker push oarcluster/$image
done
