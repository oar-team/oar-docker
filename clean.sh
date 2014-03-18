#!/bin/bash
set -e

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

source $BASEDIR/scripts/manager_oarcluster.sh

cleanup_all_containers
