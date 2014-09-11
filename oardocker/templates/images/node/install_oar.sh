#!/bin/bash
set -e

TMPDIR=$(mktemp -d --tmpdir install_oar.XXXXXXXX)
SRCDIR="$TMPDIR/src"

fail() {
    echo $@ 1>&2
    rm -rf $TMPDIR
    exit 1
}

# Create tarball
if [ -d "$1"  ]; then
    pushd $1
    TARBALL_PATH=$(make tarball 2>&1 | tail -1)
    TARBALL=$(readlink -m "$1/$TARBALL_PATH")
    popd
else
    TARBALL=$1
    [ -n "$TARBALL" ] || fail "error: You must provide a URL to a OAR tarball"
    if [ ! -r "$TARBALL" ]; then
        curl $TARBALL -o $TMPDIR/oar-tarball.tar.gz
        TARBALL=$TMPDIR/oar-tarball.tar.gz
    else
        TARBALL="$(readlink -m $TARBALL)"
    fi
fi

VERSION=$(tar xfz $TARBALL --wildcards "*/sources/core/common-libs/lib/OAR/Version.pm" --to-command "grep -e 'my \$OARVersion'" | sed -e 's/^[^"]\+"\(.\+\)";$/\1/')
[ -n "${VERSION}" ] || fail "error: fail to retrieve OAR version"

mkdir $SRCDIR
tar xf $TARBALL -C $SRCDIR

# Install OAR
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local node-build
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local node-install
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local node-setup

rm -rf "$TMPDIR"

echo "Nothing to do to configure oar node !"

echo "$VERSION" | tee /oar_version
