#!/bin/bash
set -e

BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

VERSION=$(cat $BASEDIR/version.txt)

SERVER_IMAGE="oarcluster/server:$VERSION"
FRONTEND_IMAGE="oarcluster/frontend:$VERSION"
NODE_IMAGE="oarcluster/node:$VERSION"
NAMESERVER_IMAGE="oarcluster/dnsmasq"

VOLUME_MAP=""
NUM_NODES=""
CONNECT_SSH=""

source $BASEDIR/scripts/manager_oarcluster.sh

function print_help() {
    echo "usage: $0 [-n <#num_nodes>] [-v <data_directory>] [-c]"
}

function parse_options() {
    while getopts "n:cv:h" opt; do
        case $opt in
        n)
            NUM_NODES=$OPTARG
          ;;
        c)
            CONNECT_SSH=1
          ;;
        h)
            print_help
            exit 0
          ;;
        v)
            VOLUME_MAP=$OPTARG
          ;;
        esac
    done

    if [ ! "$VOLUME_MAP" == "" ]; then
        echo "data volume chosen: $VOLUME_MAP"
        VOLUME_MAP="-v $VOLUME_MAP:/data"
    fi
    if [[ -z "$NUM_NODES" ]]; then
        print_help 
        exit 2
    fi
}


if [[ "$#" -eq 0 ]]; then
    print_help
    exit 1
fi

parse_options $@

start_dns $NAMESERVER_IMAGE

start_server $SERVER_IMAGE
start_frontend $FRONTEND_IMAGE

start_nodes $NODE_IMAGE $NUM_NODES

copy_ssh_config
print_cluster_info

if [[ -n "$CONNECT_SSH" ]]; then
    echo "Auto connecting to the frontend..."
    sleep 1
    ssh -F "$SSH_CONFIG" frontend
fi
