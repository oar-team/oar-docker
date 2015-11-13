#!/bin/bash
set -e

TMPDIR=$(mktemp -d --tmpdir install_oar.XXXXXXXX)
SRCDIR="$TMPDIR/src"

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
    test -n "$(git status --porcelain)" && DIRTY_GIT="*" || DIRTY_GIT=""
    VERSION="$(git describe)${DIRTY_GIT}"
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
    VERSION=$(tar xfz $TARBALL --wildcards "*/sources/core/common-libs/lib/OAR/Version.pm" --to-command "grep -e 'my \$OARVersion'" | sed -e 's/^[^"]\+"\(.\+\)";$/\1/')
    COMMENT="OAR ${VERSION} (tarball)"
    tar xf $TARBALL -C $SRCDIR
    [ -n "${VERSION}" ] || fail "error: fail to retrieve OAR version"
    SRCDIR=$SRCDIR/oar-${VERSION}
fi

# Install OAR
make -C $SRCDIR PREFIX=/usr/local user-build tools-build node-build
make -C $SRCDIR PREFIX=/usr/local user-install drawgantt-svg-install monika-install www-conf-install api-install tools-install node-install
make -C $SRCDIR PREFIX=/usr/local user-setup drawgantt-svg-setup monika-setup www-conf-setup api-setup tools-setup node-setup

# Configure MOTD
sed -i s/__OAR_VERSION__/${VERSION}/ /etc/motd
chmod 644 /etc/motd

# Configure oar-node for cosystem/deploy jobs
# Copy initd scripts
if [ -f /usr/local/share/oar/oar-node/init.d/oar-node ]; then
    cat /usr/local/share/oar/oar-node/init.d/oar-node > /etc/init.d/oar-node
    chmod +x  /etc/init.d/oar-node
fi

if [ -f /usr/local/share/doc/oar-node/examples/init.d/oar-node ]; then
    cat /usr/local/share/doc/oar-node/examples/init.d/oar-node > /etc/init.d/oar-node
    chmod +x  /etc/init.d/oar-node
fi


if [ -f /usr/local/share/oar/oar-node/default/oar-node ]; then
    cat /usr/local/share/oar/oar-node/default/oar-node > /etc/default/oar-node
fi

if [ -f /usr/local/share/doc/oar-node/examples/default/oar-node ]; then
    cat /usr/local/share/doc/oar-node/examples/default/oar-node > /etc/default/oar-node
fi

## Configure HTTP
mv /var/www/html/index.nginx-debian.html /var/www/html/index.html

rm -f /etc/oar/api-users
htpasswd -b -c /etc/oar/api-users docker docker
htpasswd -b /etc/oar/api-users oar oar

# configure API on nginx

OLD_OARAPI_CGI="/usr/local/lib/cgi-bin/oarapi/oarapi.cgi"

if [ -f "/usr/local/lib/cgi-bin/oarapi/oarapi.cgi" ]; then
    OLD_OARAPI_CGI="/var/www/cgi-bin/oarapi/oarapi.cgi"
fi

if [ -f "/usr/local/lib/cgi-bin/oarapi/oarapi.cgi" ]; then
    mkdir -p /var/www/cgi-bin/oarapi/
    ln -sf /usr/local/lib/cgi-bin/oarapi/oarapi.cgi /var/www/cgi-bin/oarapi/oarapi.cgi
fi

if [ -f "/usr/local/lib/cgi-bin/monika.cgi" ]; then
    mkdir -p /var/www/cgi-bin/monika/
    ln -sf /usr/local/lib/cgi-bin/monika.cgi /var/www/cgi-bin/monika/monika.cgi
fi

if [ -f "/var/www/cgi-bin/monika.cgi" ]; then
    mkdir -p /var/www/cgi-bin/monika/
    ln -sf /var/www/cgi-bin/monika.cgi /var/www/cgi-bin/monika/monika.cgi
fi

sed -e "s/^\(hostname = \).*/\1server/" -i /etc/oar/monika.conf
sed -e "s/^\(username.*\)oar.*/\1oar_ro/" -i /etc/oar/monika.conf
sed -e "s/^\(password.*\)oar.*/\1oar_ro/" -i /etc/oar/monika.conf
sed -e "s/^\(dbtype.*\)mysql.*/\1psql/" -i /etc/oar/monika.conf
sed -e "s/^\(dbport.*\)3306.*/\15432/" -i /etc/oar/monika.conf
sed -e "s/^\(hostname.*\)localhost.*/\1server/" -i /etc/oar/monika.conf
ln -s /usr/local/share/oar-web-status/monika.css /var/www/html/monika.css

# Edit oar.conf
sed -e 's/^LOG_LEVEL\=\"2\"/LOG_LEVEL\=\"3\"/' -i /etc/oar/oar.conf
sed -e 's/^DB_HOSTNAME\=.*/DB_HOSTNAME\=\"server\"/' -i /etc/oar/oar.conf
sed -e 's/^SERVER_HOSTNAME\=.*/SERVER_HOSTNAME\=\"server\"/' -i /etc/oar/oar.conf
sed -e 's/^#\(TAKTUK_CMD\=\"\/usr\/bin\/taktuk \-t 30 \-s\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^#\(PINGCHECKER_TAKTUK_ARG_COMMAND\=\"broadcast exec timeout 5 kill 9 \[ true \]\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_TYPE\)=.*/\1="Pg"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_PORT\)=.*/\1="5432"/' -i /etc/oar/oar.conf

sed -e 's/^#\(CPUSET_PATH\=\"\/oar\".*\)/\1/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_PASSWD\)=.*/\1="oar"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_LOGIN\)=.*/\1="oar"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_PASSWD_RO\)=.*/\1="oar_ro"/' -i /etc/oar/oar.conf
sed -e 's/^\(DB_BASE_LOGIN_RO\)=.*/\1="oar_ro"/' -i /etc/oar/oar.conf

# Configure cosystem and deploy jobs
sed -e 's/^\(COSYSTEM_HOSTNAME\)=.*/\1="frontend"/' -i /etc/oar/oar.conf
sed -e 's/^\(DEPLOY_HOSTNAME\)=.*/\1="frontend"/' -i /etc/oar/oar.conf

# Configure oarsh
sed -e 's/^#\(GET_CURRENT_CPUSET_CMD.*oardocker.*\)/\1/' -i /etc/oar/oar.conf

# Configure phppgadmin
sed -i "s/\$conf\['extra_login_security'\] = true;/\$conf\['extra_login_security'\] = false;/g" /etc/phppgadmin/config.inc.php
sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = 'localhost';/\$conf\['servers'\]\[0\]\['host'\] = 'server';/g" /etc/phppgadmin/config.inc.php
# chown -R  www-data:www-data /usr/share/phppgadmin/
ln -s /usr/share/phppgadmin /var/www/html/phppgadmin

## Visualization tools
# Configure drawgantt-svg
sed -i "s/\$CONF\['db_type'\]=\"mysql\"/\$CONF\['db_type'\]=\"pg\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\$CONF\['db_server'\]=\"127.0.0.1\"/\$CONF\['db_server'\]=\"server\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\$CONF\['db_port'\]=\"3306\"/\$CONF\['db_port'\]=\"5432\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\"My OAR resources\"/\"Docker oardocker resources\"/g" /etc/oar/drawgantt-config.inc.php
ln -s /usr/local/share/oar-web-status/drawgantt-svg /var/www/html/drawgantt
ln -s /usr/local/share/oar-web-status/drawgantt-svg /var/www/html/drawgantt-svg

# Fix permissions
chmod a+r /etc/oar/oar.conf
chown oar  /etc/oar/monika.conf

# Disable all sysvinit services
ls /etc/init.d/* | xargs -I {} basename {} | xargs -I {} systemctl disable {} 2> /dev/null || true

echo "$VERSION" | tee /oar_version
echo "$COMMENT"
