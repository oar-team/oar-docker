#!/bin/bash
set -e

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
make -C $SRCDIR PREFIX=/usr/local node-build
make -C $SRCDIR PREFIX=/usr/local node-install
make -C $SRCDIR PREFIX=/usr/local node-setup

# Copy initd scripts
if [ -f /usr/local/share/oar/oar-node/init.d/oar-node ]; then
    cat /usr/local/share/oar/oar-node/init.d/oar-node > /etc/init.d/oar-node
    chmod +x  /etc/init.d/oar-node
fi

if [ -f /usr/local/share/doc/oar-node/examples/init.d/oar-node ]; then
    cat /usr/local/share/oar/oar-node/init.d/oar-node > /etc/init.d/oar-node
    chmod +x  /etc/init.d/oar-node
fi


if [ -f /usr/local/share/oar/oar-node/default/oar-node ]; then
    cat /usr/local/share/oar/oar-node/default/oar-node > /etc/default/oar-node
fi

if [ -f /usr/local/share/doc/oar-node/examples/default/oar-node ]; then
    cat /usr/local/share/doc/oar-node/examples/default/oar-node > /etc/default/oar-node
fi

# Copy systemd unit
if [ -f /usr/local/share/oar/oar-node/systemd/oar-node.service ]; then
    mkdir -p /usr/local/lib/systemd/system
    cat /usr/local/share/oar/oar-node/systemd/oar-node.service > /usr/local/lib/systemd/system/oar-node.service
fi

sed -e 's/^#\(GET_CURRENT_CPUSET_CMD.*oardocker.*\)/\1/' -i /etc/oar/oar.conf

# Disable all sysvinit services
ls /etc/init.d/* | xargs -I {} basename {} | xargs -I {} systemctl disable {} 2> /dev/null || true

# Enable oar-node systemd unit
if [ -f /usr/local/share/oar/oar-node/systemd/oar-node.service ]; then
    systemctl enable oar-node
fi

echo "$VERSION" | tee /oar_version
echo "$COMMENT"
