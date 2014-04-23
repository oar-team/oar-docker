#!/bin/bash
set -o errexit

DOCKER=${DOCKER:-docker}
WORKDIR=/tmp/oarcluster
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

SSH_CONFIG="$WORKDIR/ssh_config"
SSH_KEY="$WORKDIR/ssh_insecure_key"
DNS_IP=
DNSDIR="$WORKDIR/dnsmasq.d"
DNSFILE="${DNSDIR}/0hosts"
SSH_SERVER_PORT=49217
SSH_FRONTEND_PORT=49218
HTTP_FRONTEND_PORT=48080
VOLUME_MAP=
NUM_NODES=
CONNECT_SSH=


fail() {
    echo $@ 1>&2
    exit 1
}

start_dns() {
    image="oarcluster/dnsmasq:latest"
    mkdir -p $DNSDIR
    echo > $DNSFILE
    DNS_CID=$($DOCKER run --dns 127.0.0.1 -d -h dns \
              --name oarcluster_dns -v $DNSDIR:/etc/dnsmasq.d \
              $image)
    if [ "$DNS_CID" = "" ]; then
        fail "error: could not start dns container from image $image"
    fi

    echo "Started oarcluster_dns : $DNS_CID"

    DNS_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $DNS_CID)
    echo "address=\"/dns/$DNS_IP\"" >> $DNSFILE
}

start_server() {
    image="oarcluster/server:latest"
    SERVER_CID=$($DOCKER run -d -t --dns $DNS_IP -h server \
                 --env "NUM_NODES=$NUM_NODES" --name oarcluster_server \
                 -p 127.0.0.1:$SSH_SERVER_PORT:22 $VOLUME_MAP $image \
                 /sbin/my_init --enable-insecure-key)

    if [ "$SERVER_CID" = "" ]; then
        fail "error: could not start server container from image $image"
    fi

    echo "Started oarcluster_server : $SERVER_CID"
    SERVER_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $SERVER_CID)
    echo "address=\"/server/$SERVER_IP\"" >> $DNSFILE
}

start_frontend() {
    image="oarcluster/frontend:latest"
    FRONTEND_CID=$($DOCKER run -d -t --dns $DNS_IP -h frontend \
                   --env "NUM_NODES=$NUM_NODES" --name oarcluster_frontend \
                   -p 127.0.0.1:$SSH_FRONTEND_PORT:22 \
                   -p 127.0.0.1:$HTTP_FRONTEND_PORT:80 \
                   $VOLUME_MAP $image \
                   /sbin/my_init --enable-insecure-key)

    if [ "$FRONTEND_CID" = "" ]; then
        fail "error: could not start frontend container from image $image"
    fi
    echo "Started oarcluster_frontend : $FRONTEND_CID"
    FRONTEND_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $FRONTEND_CID)
    echo "address=\"/frontend/$FRONTEND_IP\"" >> $DNSFILE
}

start_nodes() {
    image="oarcluster/node:latest"
    for i in `seq 1 $NUM_NODES`; do
        hostname="node${i}"
        NODE_CID=$($DOCKER run -d -t --privileged --dns $DNS_IP \
                   --name oarcluster_$hostname \
                   -h $hostname $VOLUME_MAP $image \
                   /sbin/my_init /sbin/oar_node_cmd --enable-insecure-key)

        if [ "$NODE_CID" = "" ]; then
            fail "error: could not start node container from image $image"
        fi

        echo "Started oarcluster_$hostname : $NODE_CID"
        NODE_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $NODE_CID)
        echo "address=\"/$hostname/$NODE_IP\"" >> $DNSFILE
    done
}


copy_ssh_config() {
    cp "$BASEDIR/base/config/insecure_key" "$SSH_KEY"
    chmod 600 $SSH_KEY
    chown $USER:$USER $SSH_KEY
    cat > "$SSH_CONFIG" <<< "
Host *
  HostName 127.0.0.1
  User docker
  IdentityFile $SSH_KEY
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentitiesOnly yes
  LogLevel FATAL
  ForwardAgent yes
  ControlPath $(dirname $SSH_KEY)/master-%l-%r@%h:%p
  ControlMaster auto
  Compression yes
  Protocol 2

Host frontend
  Port $SSH_FRONTEND_PORT

Host server
  Port $SSH_SERVER_PORT
"
}

print_cluster_info() {
    echo ""
    echo "***********************************************************************"
    echo ""
    echo "API  : http://localhost:$HTTP_FRONTEND_PORT/oarapi/"
    echo "Monika : http://localhost:$HTTP_FRONTEND_PORT/monika"
    echo "Drawgantt : http://localhost:$HTTP_FRONTEND_PORT/drawgantt-svg"
    echo "PhpPgAdmin : http://localhost:$HTTP_FRONTEND_PORT/phppgadmin"
    echo ""
    echo "SSH  : ssh -F $SSH_CONFIG frontend"
    echo "       ssh -F $SSH_CONFIG server"
    echo ""
    echo "Logs : $DOCKER logs -f oarcluster_server"
    echo "       $DOCKER logs -f oarcluster_frontend"
    echo "       $DOCKER logs -f oarcluster_nodexxx"
    echo ""
    echo "Data : $VOLUME_MAP"
    echo ""
    echo "***********************************************************************"
}

print_help() {
    echo "usage: $0 -n <#nodes> [-v <volume>] [-c]"
}

parse_options() {
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
        echo "Data volume chosen: $VOLUME_MAP"
        VOLUME_MAP="-v $VOLUME_MAP:/data"
    else
        mkdir -p "${BASEDIR}/shared_data"
        echo "Default data volume used: ${BASEDIR}/shared_data"
        VOLUME_MAP="-v ${BASEDIR}/shared_data:/data"
    fi
}

parse_options $@

if [[ "$#" -eq 0 ]] || [[ -z "$NUM_NODES" ]]; then
    print_help
    fail "You must indicate number of nodes"
fi

source $BASEDIR/clean.sh
start_dns
start_server
start_frontend
start_nodes

copy_ssh_config
print_cluster_info

if [[ -n "$CONNECT_SSH" ]]; then
    echo -n "Waiting for SSH to become available"
    until bash -c "ssh -F "$SSH_CONFIG" frontend true" &> /dev/null
    do
      sleep 1
      echo -n "."
    done
    echo ""
    echo "Auto connecting to the frontend..."
    ssh -F "$SSH_CONFIG" frontend
fi
