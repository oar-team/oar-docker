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

# Adapt oar.conf
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

sed -e 's/^\(COSYSTEM_HOSTNAME\)=.*/\1="frontend"/' -i /etc/oar/oar.conf
sed -e 's/^\(DEPLOY_HOSTNAME\)=.*/\1="frontend"/' -i /etc/oar/oar.conf

# Configure oarsh
sed -e 's/^#\(GET_CURRENT_CPUSET_CMD.*oardocker.*\)/\1/' -i /etc/oar/oar.conf

# Configure OAR restful api for Apache2
rm -f /etc/oar/api-users
htpasswd -b -c /etc/oar/api-users docker docker
htpasswd -b /etc/oar/api-users oar oar

sed -i -e '1s@^/var/www.*@/usr/local/lib/cgi-bin@' /etc/apache2/suexec/www-data                                    
sed -i -e 's@#\(FastCgiWrapper /usr/lib/apache2/suexec\)@\1@' /etc/apache2/mods-available/fastcgi.conf       

a2enmod suexec
a2enmod headers
a2enmod rewrite

perl -i -pe 's/Require local/Require all granted/; s/#(ScriptAlias \/oarapi-priv)/$1/; $do=1 if /#<Location \/oarapi-priv>/; if ($do) { $do=0 if /#<\/Location>/; s/^#// }' /etc/oar/apache2/oar-restful-api.conf

# Add newoarapi-priv location
a2enmod proxy
a2enmod proxy_http
(cd /etc/oar/apache2/ && patch -p0) <<'EOF'
--- oar-restful-api.conf.orig
+++ oar-restful-api.conf
@@ -176,4 +176,19 @@
 #  </IfModule>
 #</Location>
 
+ProxyRequests off
+ProxyPass "/newoarapi-priv" "http://127.0.0.1:9090"
+
+<Location /newoarapi-priv>
+    Options +ExecCGI -MultiViews +FollowSymLinks
+    AuthType      basic
+    AuthUserfile  /etc/oar/api-users
+    AuthName      "OAR API authentication"
+    Require valid-user
+    RewriteEngine On
+    RewriteCond %{REMOTE_USER} (.*)
+    RewriteRule .* - [E=X_REMOTE_IDENT:%1]
+    RequestHeader add X_REMOTE_IDENT %{X_REMOTE_IDENT}e
+</Location>
+
 </virtualhost>
EOF

a2enconf oar-restful-api

# Configure oar-web-status for Apache2 (monika + drawgantt-svg)

a2enmod cgi
# Change cgi-bin path to /usr/local
sed -i -e "s@/usr/lib/cgi-bin@/usr/local/lib/cgi-bin@" /etc/apache2/conf-available/serve-cgi-bin.conf

sed -e "s/^\(clustername = \).*/\1oardocker for OAR $VERSION/" -i /etc/oar/monika.conf
sed -e "s/^\(hostname = \).*/\1server/" -i /etc/oar/monika.conf
sed -e "s/^\(username.*\)oar.*/\1oar_ro/" -i /etc/oar/monika.conf
sed -e "s/^\(password.*\)oar.*/\1oar_ro/" -i /etc/oar/monika.conf
sed -e "s/^\(dbtype.*\)mysql.*/\1psql/" -i /etc/oar/monika.conf
sed -e "s/^\(dbport.*\)3306.*/\15432/" -i /etc/oar/monika.conf
sed -e "s/^\(hostname.*\)localhost.*/\1server/" -i /etc/oar/monika.conf
chown www-data /etc/oar/monika.conf

sed -i "s/\$CONF\['db_type'\]=\"mysql\"/\$CONF\['db_type'\]=\"pg\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\$CONF\['db_server'\]=\"127.0.0.1\"/\$CONF\['db_server'\]=\"server\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\$CONF\['db_port'\]=\"3306\"/\$CONF\['db_port'\]=\"5432\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\"My OAR resources\"/\"oardocker resources for OAR $VERSION\"/g" /etc/oar/drawgantt-config.inc.php

a2enconf oar-web-status

# Configure phppgadmin
sed -i "s/\$conf\['extra_login_security'\] = true;/\$conf\['extra_login_security'\] = false;/g" /etc/phppgadmin/config.inc.php
sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = 'localhost';/\$conf\['servers'\]\[0\]\['host'\] = 'server';/g" /etc/phppgadmin/config.inc.php
sed -i "s/Require local/Require all granted/" /etc/apache2/conf-available/phppgadmin.conf

# Disable all sysvinit services
ls /etc/init.d/* | xargs -I {} basename {} | xargs -I {} systemctl disable {} 2> /dev/null || true

echo "$VERSION" | tee /oar_version
echo "$COMMENT"
