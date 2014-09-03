#!/bin/bash
set -e

WORKDIR=/tmp/postinstall
SRCDIR=$WORKDIR/src
GIT_SRC=$WORKDIR/oar-git

fail() {
    echo $@ 1>&2
    rm -rf $TMPDIR
    exit 1
}

[ -n "$OAR_INSTALL_METHOD" ] || fail "You must set OAR_INSTALL_METHOD variable"

# Create tarball
if [ $OAR_INSTALL_METHOD = "git" ]; then
    pushd $GIT_SRC
    TARBALL_PATH=$(make tarball 2>&1 | tail -1)
    TARBALL=$(readlink -m "$GIT_SRC/$TARBALL_PATH")
    popd
else

[ -r "$TARBALL" ] || fail "error: You must provide a OAR tarball"
VERSION=$(tar xfz $TARBALL --wildcards "*/sources/core/common-libs/lib/OAR/Version.pm" --to-command "grep -e 'my \$OARVersion'" | sed -e 's/^[^"]\+"\(.\+\)";$/\1/')
[ -n "${VERSION}" ] || fail "error: fail to retrieve OAR version"

mkdir $SRCDIR
tar xf $TARBALL -C $SRCDIR

# Install OAR
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local server-build
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local server-install
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local server-setup


# Copy initd scripts
if [ ! -f /usr/local/share/oar/oar-server/init.d/oar-server ]; then
    cat /usr/local/share/oar/oar-server/init.d/oar-server > /etc/init.d/oar-server
    chmod +x  /etc/init.d/oar-server
fi

if [ ! -f /usr/local/share/doc/oar-server/examples/init.d/oar-server ]; then
    cat /usr/local/share/oar/oar-server/init.d/oar-server > /etc/init.d/oar-server
    chmod +x  /etc/init.d/oar-server
fi


if [ ! -f /usr/local/share/oar/oar-server/default/oar-server ]; then
    cat /usr/local/share/oar/oar-server/default/oar-server > /etc/default/oar-server
fi

if [ ! -f /usr/local/share/doc/oar-server/examples/default/oar-server ]; then
    cat /usr/local/share/doc/oar-server/examples/default/oar-server > /etc/default/oar-server
fi

## Initialize postgres
PGSQL_CONFDIR=/etc/postgresql/9.1/main/
# configure PostgreSQL to listen for remote connections
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PGSQL_CONFDIR/postgresql.conf
# configure PostgreSQL to accept remote connections (from any host):
echo "host all all 0.0.0.0/0 md5" >> $PGSQL_CONFDIR/pg_hba.conf

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
# Use cpuset inside container
sudo sed -i 's/job_resource_manager_cgroups\.pl/job_resource_manager\.pl/g' /etc/oar/oar.conf

# Create OAR database
service postgresql restart
/usr/local/sbin/oar-database --create --db-is-local --db-admin-user root
/usr/local/sbin/oarproperty -a core
/usr/local/sbin/oarproperty -a cpu

sed -e 's/^DB_HOSTNAME\=\"localhost\"/DB_HOSTNAME\=\"server\"/' -i /etc/oar/oar.conf
sed -e 's/^SERVER_HOSTNAME\=\"localhost\"/SERVER_HOSTNAME\=\"server\"/' -i /etc/oar/oar.conf

sed -e 's/#exit/exit/' -i /etc/oar/job_resource_manager.pl

chown oar:oar /etc/oar/job_resource_manager.pl
chmod +x /etc/oar/job_resource_manager.pl

echo "oar-$VERSION"
