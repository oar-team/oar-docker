#!/bin/bash
DNS_IP=
SSH_CONFIG="/tmp/oarcluster_ssh_config"
SSH_KEY="/tmp/oarcluster_ssh_insecure_key"
DNSDIR="/tmp/oarcluster_dnsdir"
DNSFILE="${DNSDIR}/0hosts"
SERVER_CID=
SSH_SERVER_PORT=
FRONTEND_CID=
SSH_FRONTEND_PORT=
HTTP_FRONTEND_PORT=


function cleanup_all_containers() {
    echo "Cleanup old containers"
    docker ps -a | grep "oarcluster" | awk '{print $1}' | xargs docker stop
    docker ps -a | grep "oarcluster" | awk '{print $1}' | xargs docker rm
    echo "OK"
}


function cleanup_intermediate_images() {
    echo "Cleanup intermediate images"
    docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi
    echo "OK"
}

# starts the dnsmasq dns
function start_dns() {
    mkdir -p $DNSDIR
    echo > $DNSFILE
    DNS_CID=$(docker run --dns 127.0.0.1 -d -h dns \
              --name oarcluster_dns -v $DNSDIR:/etc/dnsmasq.d $1)
    if [ "$DNS_CID" = "" ]; then
        echo "error: could not start dns container from image $1"
        exit 1
    fi

    echo "oarcluster_dns : $DNS_CID"

    DNS_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $DNS_CID)
    echo "address=\"/dns/$DNS_IP\"" >> $DNSFILE
}

# starts the oar server container
function start_server() {
    SERVER_CID=$(docker run -d -t --dns $DNS_IP -h server \
                 --env "NUM_NODES=$NUM_NODES" --name oarcluster_server \
                 -p 127.0.0.1::22 $VOLUME_MAP $1 \
                 --enable-insecure-key)

    SSH_SERVER_PORT=$(docker port $SERVER_CID 22 | cut -d':' -f2)

    if [ "$SERVER_CID" = "" ]; then
        echo "error: could not start server container from image $1"
        exit 1
    fi

    echo "oarcluster_server : $SERVER_CID"
    SERVER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $SERVER_CID)
    echo "address=\"/server/$SERVER_IP\"" >> $DNSFILE
}


function start_frontend() {
    FRONTEND_CID=$(docker run -d -t --dns $DNS_IP -h frontend \
                   --env "NUM_NODES=$NUM_NODES" --name oarcluster_frontend \
                   -p 127.0.0.1::22 -p 127.0.0.1::80 $VOLUME_MAP $1 \
                   --enable-insecure-key)

    SSH_FRONTEND_PORT=$(docker port $FRONTEND_CID 22 | cut -d':' -f2)
    HTTP_FRONTEND_PORT=$(docker port $FRONTEND_CID 80 | cut -d':' -f2)
    if [ "$FRONTEND_CID" = "" ]; then
        echo "error: could not start frontend container from image $1"
        exit 1
    fi
    echo "oarcluster_frontend : $FRONTEND_CID"
    FRONTEND_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $FRONTEND_CID)
    echo "address=\"/frontend/$FRONTEND_IP\"" >> $DNSFILE
}

# starts a number of oar nodes
function start_nodes() {
    for i in `seq 1 $NUM_NODES`; do
        hostname="node${i}"
        NODE_CID=$(docker run -d -t --privileged --dns $DNS_IP \
                   --name oarcluster_$hostname \
                   -h $hostname $VOLUME_MAP $1 \
                   --enable-insecure-key)

        if [ "$NODE_CID" = "" ]; then
            echo "error: could not start node container from image $1"
            exit 1
        fi

        echo "oarcluster_$hostname : $NODE_CID"
        NODE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $NODE_CID)
        echo "address=\"/$hostname/$NODE_IP\"" >> $DNSFILE
    done
}


function copy_ssh_config() {
    cp "$BASEDIR/base/insecure_key" "$SSH_KEY"
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
  ControlPath ~/.ssh/master-%l-%r@%h:%p
  ControlMaster auto
  Compression yes
  Protocol 2

Host frontend
  Port $SSH_FRONTEND_PORT

Host server
  Port $SSH_SERVER_PORT
"
}


# prints out information on the cluster
function print_cluster_info() {
    echo ""
    echo "***********************************************************************"
    echo ""
    echo "API  : http://localhost:$HTTP_FRONTEND_PORT/"
    echo "SSH  : ssh -F $SSH_CONFIG frontend"
    echo "       ssh -F $SSH_CONFIG server"
    echo ""
    echo "Logs : docker logs -f oarcluster_server"
      echo ""
    echo "Data : $VOLUME_MAP"
    echo ""
    echo "***********************************************************************"
}
