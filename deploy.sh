#!/bin/bash
set -o errexit

DOCKER=${DOCKER:-docker}
WORKDIR=/tmp/oarcluster
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
SSH_CONFIG="$WORKDIR/ssh_config"
SSH_KEY="$WORKDIR/ssh_insecure_key"
DNS_IP=
DNSDIR="$WORKDIR/dnsmasq.d"
DNSFILE="${DNSDIR}/hosts"
SSH_SERVER_PORT=49217
SSH_FRONTEND_PORT=49218
HTTP_FRONTEND_PORT=48080
VOLUMES_MAP=
VOLUMES=
NUM_NODES=
CONNECT_SSH=
ENABLE_COLMET=

fail() {
    echo $@ 1>&2
    exit 1
}

start_dns() {
    # Reset DNS configuration
    mkdir -p $DNSDIR
    echo > $DNSFILE
    image="oarcluster/dnsmasq:latest"
    hostname="dns"
    DNS_CID=$($DOCKER run --dns 127.0.0.1 -d -h $hostname \
              --name oarcluster_dns -v $DNSDIR:/etc/dnsmasq.d \
              $image)
    if [ "$DNS_CID" = "" ]; then
        fail "error: could not start dns container from image $image"
    fi

    echo "Started oarcluster_dns : $DNS_CID"

    DNS_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $DNS_CID)
    echo "$DNS_IP dns" >> $DNSFILE
}

start_server() {
    image=${1:-"oarcluster/server:latest"}
    hostname="server"
    SERVER_CID=$($DOCKER run -d -t --dns $DNS_IP -h $hostname \
                 --env "NUM_NODES=$NUM_NODES" --env "COLOR=red" \
                 --name oarcluster_server  --privileged \
                 -p 127.0.0.1:$SSH_SERVER_PORT:22 $VOLUMES_MAP $image \
                 /sbin/my_init /sbin/taillogs --enable-insecure-key)

    if [ "$SERVER_CID" = "" ]; then
        fail "error: could not start server container from image $image"
    fi

    echo "Started oarcluster_server : $SERVER_CID"
    SERVER_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $SERVER_CID)
    echo "$SERVER_IP $hostname" >> $DNSFILE
}

start_server_colmet() {
    start_server "oarcluster/server-colmet:latest"
}

start_frontend() {
    image="oarcluster/frontend:latest"
    hostname="frontend"
    FRONTEND_CID=$($DOCKER run -d -t --dns $DNS_IP -h $hostname \
                   --env "NUM_NODES=$NUM_NODES" --env "COLOR=blue" \
                   --name oarcluster_frontend \
                   -p 127.0.0.1:$SSH_FRONTEND_PORT:22 \
                   -p 127.0.0.1:$HTTP_FRONTEND_PORT:80 \
                   $VOLUMES_MAP $image \
                   /sbin/my_init /sbin/taillogs --enable-insecure-key)

    if [ "$FRONTEND_CID" = "" ]; then
        fail "error: could not start frontend container from image $image"
    fi
    echo "Started oarcluster_frontend : $FRONTEND_CID"
    FRONTEND_IP=$($DOCKER inspect --format '{{ .NetworkSettings.IPAddress }}' $FRONTEND_CID)
    echo "$FRONTEND_IP $hostname" >> $DNSFILE
}

start_nodes() {
    image=${1:-"oarcluster/node:latest"}
    cmd=${2:-"/sbin/my_init /sbin/taillogs --enable-insecure-key"}
    for i in `seq 1 $NUM_NODES`; do
        name="node${i}"
        hostname="${name}"
        NODE_CID=$(docker run -d -t --privileged --dns $DNS_IP \
                   -h $hostname --env "COLOR=yellow" \
                   --name oarcluster_$name $VOLUMES_MAP $image \
                   $cmd )

        if [ "$NODE_CID" = "" ]; then
            fail "error: could not start node container from image $image"
        fi

        echo "Started oarcluster_$name : $NODE_CID"
        NODE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $NODE_CID)
        echo "$NODE_IP $hostname" >> $DNSFILE
    done
}

start_nodes_colmet() {
    start_nodes "oarcluster/node-colmet:latest" "/sbin/init_kvm /sbin/my_init /sbin/taillogs --enable-insecure-key"
}

copy_ssh_config() {
    cp "$BASEDIR/images/base/assets/config/insecure_key" "$SSH_KEY"
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
  ControlPersist yes
  Compression yes
  Protocol 2

Host frontend
  Port $SSH_FRONTEND_PORT

Host server
  Port $SSH_SERVER_PORT
"
}

$DOCKER 2> /dev/null || fail "error: Docker ($DOCKER) executable no found. Make sure Docker is installed and/or use the DOCKER variable to set Docker executable."

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
    echo "Data : "
if [ "$VOLUMES" == "" ]; then
    echo "       ${BASEDIR}/shared_data ~> /data"
else
    _volumes=($VOLUMES)
    for vol in "${_volumes[@]}"; do
      array=(${vol//:/ })
      echo "       ${array[0]} ~> ${array[1]}"
    done
fi
    echo ""
    echo "***********************************************************************"
}

print_help() {
    echo "usage: $0 -n <#nodes> [[-v </host:/container>]] [-c|--connect] [--colmet]"
}

args=$(getopt -l "connect,volume,colmet,nodes,help:" -o "n:cv:h" -- "$@")

eval set -- "$args"

while [ $# -ge 1 ]; do
    case "$1" in
    --)
        # No more options left.
        shift
        break
       ;;
    -n|--nodes)
        NUM_NODES=$2
        shift
      ;;
    -c|--connect)
        CONNECT_SSH=1
      ;;
    -h|--help)
        print_help
        exit 0
      ;;
    -v|--volume)
        VOLUMES="$VOLUMES $2"
        shift
      ;;
    --colmet)
        ENABLE_COLMET=1
      ;;
    esac
    shift
done

if [[ -z "$NUM_NODES" ]]; then
    print_help
    fail "You must indicate number of nodes"
fi

if [ "$VOLUMES" == "" ]; then
    mkdir -p "${BASEDIR}/shared_data"
    echo "Default data volume used: ${BASEDIR}/shared_data"
    VOLUMES_MAP="-v ${BASEDIR}/shared_data:/data"
else
    _volumes=($VOLUMES)
    for vol in "${_volumes[@]}"; do
      VOLUMES_MAP="$VOLUMES_MAP -v $vol"
    done
fi

source $BASEDIR/clean.sh


if [[ -n "$ENABLE_COLMET" ]]; then
  start_dns
  start_server_colmet
  start_frontend
  start_nodes_colmet
else
  start_dns
  start_server
  start_frontend
  start_nodes
fi

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

