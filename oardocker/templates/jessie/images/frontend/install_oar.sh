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
make -C $SRCDIR PREFIX=/usr/local user-build tools-build
make -C $SRCDIR PREFIX=/usr/local user-install drawgantt-svg-install monika-install www-conf-install api-install tools-install
make -C $SRCDIR PREFIX=/usr/local user-setup drawgantt-svg-setup monika-setup www-conf-setup api-setup tools-setup

# Configure MOTD
sed -i s/__OAR_VERSION__/${VERSION}/ /etc/motd
chmod 644 /etc/motd

## Configure HTTP
a2enmod ident
a2enmod headers
a2enmod rewrite

rm -f /etc/oar/api-users
htpasswd -b -c /etc/oar/api-users docker docker
htpasswd -b /etc/oar/api-users oar docker

cat > /etc/apache2/conf-available/oar-restful-api.conf <<"EOF"
# Example Apache2 configuration for the OAR API

# Aliases to the API.
# Be aware that the oarapi directory should only be readable by the httpd
# daemon and that the cgi inside are sgid oar. Any change to this permissions
# may cause your system to be vulnerable.
ScriptAlias /oarapi /usr/local/lib/cgi-bin/oarapi/oarapi.cgi
ScriptAlias /oarapi-debug /usr/local/lib/cgi-bin/oarapi/oarapi-debug.cgi

# FastCGI server
<IfModule mod_fastcgi.c>
FastCgiServer /usr/local/lib/cgi-bin/oarapi/oarapi.cgi
</IfModule>

# Authentication configuration for access to the API
<Directory /usr/local/lib/cgi-bin/oarapi>
     Options +ExecCGI -MultiViews +FollowSymLinks

     # FastCGI handler
     <IfModule mod_fastcgi.c>
     AddHandler fcgid-script .cgi
     </IfModule>
     Require all granted
     # Pidentd may be useful for testing without a login/passwd or when you
     # fully trust some hosts (ie users have no way to fake their login name).
     # Ident trust may be disabled into the api itself.
     <IfModule ident_module>
       IdentityCheck On

       <IfModule headers_module>
         # Set the X-REMOTE_IDENT http header value to REMOTE_IDENT env value
         RequestHeader set X_REMOTE_IDENT %{REMOTE_IDENT}e
         # or For https:
         #RequestHeader set X_REMOTE_IDENT %{REMOTE_IDENT}s
         # Or if it doesn't work, enable mod_rewrite and try this:
         <IfModule rewrite_module>
            RewriteEngine On
            RewriteCond %{REMOTE_IDENT} (.*)
            RewriteRule .* - [E=MY_REMOTE_IDENT:%1]
            RequestHeader add X-REMOTE_IDENT %{MY_REMOTE_IDENT}e
         </IfModule>
       </IfModule>

     </IfModule>
</Directory>
EOF

cat > /etc/apache2/conf-available/oar-restful-api-priv.conf <<"EOF"
ScriptAlias /oarapi-priv /usr/local/lib/cgi-bin/oarapi/oarapi.cgi
ScriptAlias /oarapi-priv-debug /usr/local/lib/cgi-bin/oarapi/oarapi.cgi

<Location /oarapi-priv>
 Options +ExecCGI -MultiViews +FollowSymLinks
 AuthType      basic
 AuthUserfile  /etc/oar/api-users
 AuthName      "OAR API authentication"
 Require valid-user
 #RequestHeader set X_REMOTE_IDENT %{REMOTE_USER}e
 RewriteEngine On
 RewriteCond %{REMOTE_USER} (.*)
 RewriteRule .* - [E=MY_REMOTE_IDENT:%1]
 RequestHeader add X-REMOTE_IDENT %{MY_REMOTE_IDENT}e
</Location>
EOF

cat > /etc/apache2/conf-available/oar-web-status.conf <<"EOF"
ScriptAlias /monika /usr/local/lib/cgi-bin/monika.cgi
Alias /monika.css /usr/local/share/oar-web-status/monika.css
Alias /drawgantt-svg /usr/local/share/oar-web-status/drawgantt-svg
Alias /drawgantt /usr/local/share/oar-web-status/drawgantt-svg
<Directory /usr/local/share/oar-web-status>
        Require all granted
        Options Indexes FollowSymlinks
</Directory>
EOF

ln -sf  /etc/apache2/conf-available/oar-restful-api.conf /etc/apache2/conf-enabled/oar-restful-api.conf
ln -sf  /etc/apache2/conf-available/oar-restful-api-priv.conf /etc/apache2/conf-enabled/oar-restful-api-priv.conf
ln -sf  /etc/apache2/conf-available/oar-web-status.conf /etc/apache2/conf-enabled/oar-web-status.conf


sed -e "s/^\(hostname = \).*/\1server/" -i /etc/oar/monika.conf
sed -e "s/^\(username.*\)oar.*/\1oar_ro/" -i /etc/oar/monika.conf
sed -e "s/^\(password.*\)oar.*/\1oar_ro/" -i /etc/oar/monika.conf
sed -e "s/^\(dbtype.*\)mysql.*/\1psql/" -i /etc/oar/monika.conf
sed -e "s/^\(dbport.*\)3306.*/\15432/" -i /etc/oar/monika.conf
sed -e "s/^\(hostname.*\)localhost.*/\1server/" -i /etc/oar/monika.conf


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

sed -e 's/^#\(GET_CURRENT_CPUSET_CMD.*oardocker.*\)/\1/' -i /etc/oar/oar.conf

# Configure phppgadmin
if [ -f /etc/apache2/conf-available/phppgadmin.conf ]; then
  # work around current bug in the package (see: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=669837)
  cat <<EOF > /etc/apache2/conf-available/phppgadmin.conf
Alias /phppgadmin /usr/share/phppgadmin

<Directory /usr/share/phppgadmin>

DirectoryIndex index.php
AllowOverride None
Require all granted

<IfModule mod_php5.c>
  php_flag magic_quotes_gpc Off
  php_flag track_vars On
  #php_value include_path .
</IfModule>
<IfModule !mod_php5.c>
  <IfModule mod_actions.c>
    <IfModule mod_cgi.c>
      AddType application/x-httpd-php .php
      Action application/x-httpd-php /cgi-bin/php
    </IfModule>
    <IfModule mod_cgid.c>
      AddType application/x-httpd-php .php
      Action application/x-httpd-php /cgi-bin/php
    </IfModule>
  </IfModule>
</IfModule>

</Directory>
EOF
  ln -sf /etc/apache2/conf-available/phppgadmin.conf /etc/apache2/conf-enabled/phppgadmin.conf
fi
sed -i "s/\$conf\['extra_login_security'\] = true;/\$conf\['extra_login_security'\] = false;/g" /etc/phppgadmin/config.inc.php
sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = 'localhost';/\$conf\['servers'\]\[0\]\['host'\] = 'server';/g" /etc/phppgadmin/config.inc.php

## Visualization tools
# Configure drawgantt-svg
sed -i "s/\$CONF\['db_type'\]=\"mysql\"/\$CONF\['db_type'\]=\"pg\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\$CONF\['db_server'\]=\"127.0.0.1\"/\$CONF\['db_server'\]=\"server\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\$CONF\['db_port'\]=\"3306\"/\$CONF\['db_port'\]=\"5432\"/g" /etc/oar/drawgantt-config.inc.php
sed -i "s/\"My OAR resources\"/\"Docker oardocker resources\"/g" /etc/oar/drawgantt-config.inc.php

echo "$VERSION" | tee /oar_version
echo "$COMMENT"
