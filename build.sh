#!/bin/bash
set -e

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

source $BASEDIR/scripts/manager_oarcluster.sh

# nameserver
docker build -t oarcluster/dnsmasq ./dnsmasq/

# base image
docker build -t oarcluster/base ./base/

# server
docker build -t oarcluster/server:${VERSION} ./server/

# frontend
docker build -t oarcluster/frontend:${VERSION} ./frontend/

# node
docker build -t oarcluster/node:${VERSION} ./node/

cleanup_intermediate_images
