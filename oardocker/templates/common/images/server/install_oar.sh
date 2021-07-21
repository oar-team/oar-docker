#!/bin/bash
set -e

IFS='.' read DEBIAN_VERSION DEBIAN_VERSION_MINOR < /etc/debian_version

TMPDIR=$(mktemp -d --tmpdir install_oar.XXXXXXXX)
SRCDIR="$TMPDIR/src"
export SYSTEMD_INIT=true

mkdir -p $SRCDIR

on_exit() {
    mountpoint -q $SRCDIR && umount $SRCDIR || true
    rm -rf $TMPDIR
}

trap "{ on_exit; kill 0; }" EXIT

fail() {
    echo $@ 1>&2
    exit 1
}

if [ -d "$1"  ]; then
    GIT_SRC="$(readlink -m $1)"
    RWSRCDIR="$TMPDIR/src-rw"
    mkdir -p $RWSRCDIR
    unionfs-fuse -o cow -o allow_other,use_ino,suid,dev,nonempty $RWSRCDIR=RW:$GIT_SRC=RO $SRCDIR
    pushd $SRCDIR
    git clean -Xfd
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    VERSION="$(git describe --tags)"
    COMMENT="OAR ${VERSION} (git branch ${BRANCH})"
    popd
    [ -n "${VERSION}" ] || fail "error: fail to retrieve OAR version"
else
    TARBALL=$1
    [ -n "$TARBALL" ] || fail "error: You must provide a URL to a OAR tarball"
    if [ ! -r "$TARBALL" ]; then
        curl $TARBALL -o $TMPDIR/oar-tarball.tar.gz
        TARBALL=$TMPDIR/oar-tarball.tar.gz
    else
        TARBALL="$(readlink -m $TARBALL)"
    fi

    if tar -tf $TARBALL --wildcards "*/setup.py"; then
        VERSION=$(tar xfz $TARBALL --wildcards "*/oar/__init__.py" --to-command "grep -e '__version__ '" | sed -e "s/^[^']\+'\(.\+\)'$/\1/" )
    else
        VERSION=$(tar xfz $TARBALL --wildcards "*/sources/core/common-libs/lib/OAR/Version.pm" --to-command "grep -e 'my \$OARVersion'" | sed -e 's/^[^"]\+"\(.\+\)";$/\1/')
    fi

    COMMENT="OAR ${VERSION} (tarball)"
    tar xf $TARBALL -C $SRCDIR
    [ -n "${VERSION}" ] || fail "error: fail to retrieve OAR version"
    SRCDIR=$SRCDIR/oar-${VERSION}
fi

MAJOR_VERSION=$(echo $VERSION | sed -e 's/\([0-9]\).*/\1/')

if [ $MAJOR_VERSION = "3" ]; then
    cd $SRCDIR; pip install .; cd -
fi

# Install OAR
make -C $SRCDIR PREFIX=/usr/local server-build
make -C $SRCDIR PREFIX=/usr/local server-install
make -C $SRCDIR PREFIX=/usr/local server-setup

# Copy initd scripts
if [ -f /usr/local/share/oar/oar-server/init.d/oar-server ]; then
    cat /usr/local/share/oar/oar-server/init.d/oar-server > /etc/init.d/oar-server
    chmod +x  /etc/init.d/oar-server
fi

if [ -f /usr/local/share/doc/oar-server/examples/init.d/oar-server ]; then
    cat /usr/local/share/doc/oar-server/examples/init.d/oar-server > /etc/init.d/oar-server
    chmod +x  /etc/init.d/oar-server
fi


if [ -f /usr/local/share/oar/oar-server/default/oar-server ]; then
    cat /usr/local/share/oar/oar-server/default/oar-server > /etc/default/oar-server
fi

if [ -f /usr/local/share/doc/oar-server/examples/default/oar-server ]; then
    cat /usr/local/share/doc/oar-server/examples/default/oar-server > /etc/default/oar-server
fi

# Copy systemd unit
if [ -f /usr/local/share/oar/oar-server/systemd/oar-server.service ]; then
    mkdir -p /usr/local/lib/systemd/system
    cat /usr/local/share/oar/oar-server/systemd/oar-server.service > /usr/local/lib/systemd/system/oar-server.service
fi

## See https://github.com/oar-team/oar-docker/issues/34
if [ -f /usr/local/share/oar/oar-server/job_resource_manager_cgroups.pl ]; then
    ln -sf /usr/local/share/oar/oar-server/job_resource_manager_cgroups.pl /etc/oar/job_resource_manager_cgroups.pl
fi

if [ -f /usr/local/share/oar/oar-server/job_resource_manager.pl ]; then
    ln -sf /usr/local/share/oar/oar-server/job_resource_manager.pl /etc/oar/job_resource_manager.pl
fi

sed -e 's/^LOG_LEVEL\=\"2\"/LOG_LEVEL\=\"3\"/' -i /etc/oar/oar.conf
sed -e 's/^#\(TAKTUK_CMD\=\"\/usr\/bin\/taktuk \-t 30 \-s\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^#\(PINGCHECKER_TAKTUK_ARG_COMMAND\=\"broadcast exec timeout 5 kill 9 \[ true \]\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_TYPE\)=.*/\1="Pg"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_PORT\)=.*/\1="5432"/' -i /etc/oar/oar.conf
sed -e 's/^#\(JOB_RESOURCE_MANAGER_PROPERTY_DB_FIELD\=\"cpuset\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^#\(CPUSET_PATH\=\"\/oar\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_PASSWD\)=.*/\1="oar"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_LOGIN\)=.*/\1="oar"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_PASSWD_RO\)=.*/\1="oar_ro"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_LOGIN_RO\)=.*/\1="oar_ro"/' -i /etc/oar/oar.conf

sed -e 's/^DB_HOSTNAME\=.*/DB_HOSTNAME\=\"server\"/' -i /etc/oar/oar.conf
sed -e 's/^SERVER_HOSTNAME\=.*/SERVER_HOSTNAME\=\"server\"/' -i /etc/oar/oar.conf

sed -e 's/^#\(GET_CURRENT_CPUSET_CMD.*oardocker.*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^\(OAREXEC_DEBUG_MODE\)=.*/\1="1"/' -i /etc/oar/oar.conf
sed -e 's/^\(COSYSTEM_HOSTNAME\)=.*/\1="frontend"/' -i /etc/oar/oar.conf
sed -e 's/^\(DEPLOY_HOSTNAME\)=.*/\1="frontend"/' -i /etc/oar/oar.conf
sed -e 's/^#\(WALLTIME_CHANGE_ENABLED\)=.*/\1="yes"/' -i /etc/oar/oar.conf
sed -e 's/^#\(WALLTIME_MAX_INCREASE\)=.*/\1=-1/' -i /etc/oar/oar.conf
sed -e 's/^#\(KILL_INNER_JOBS_WITH_CONTAINER\)=.*/\1="yes"/' -i /etc/oar/oar.conf

#This line must be uncommented if the mount_cgroup.sh script is not used
#sed -e 's/#exit/exit/' -i /etc/oar/job_resource_manager_cgroups.pl


if [ ${DEBIAN_VERSION} = '8' ]; then
    POSTGRESQL_VERSION="9.4"
elif [ ${DEBIAN_VERSION} = '9' ]; then
    POSTGRESQL_VERSION="9.6"
elif [ ${DEBIAN_VERSION} = '10' ]; then
    POSTGRESQL_VERSION="11"
else
    POSTGRESQL_VERSION="9.1"
fi

echo "Configure PostgreSQL to listen for remote connections"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$POSTGRESQL_VERSION/main/postgresql.conf
echo "Configure PostgreSQL to accept remote connections (from any host):"
echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf

echo "Starting postgresql..."
/etc/init.d/postgresql restart

echo "Waiting postgresql to be available..."
sudo -u postgres wait_pgsql

echo "Set (insecure) postgres password"
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

echo "Init database"
/usr/local/sbin/oar-database --create --db-admin-user postgres --db-admin-pass postgres --db-host localhost

echo "Stopping postgresql..."
/etc/init.d/postgresql stop

# Disable all sysvinit services
ls /etc/init.d/* | xargs -I {} basename {} | xargs -I {} systemctl disable {} 2> /dev/null || true

# Enable oar-server systemd unit
if [ -f /usr/local/share/oar/oar-server/systemd/oar-server.service ]; then
    systemctl enable oar-server
fi

echo "$VERSION" | tee /oar_version
echo "$COMMENT"
