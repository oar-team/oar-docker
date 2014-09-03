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
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local node-build
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local node-install
make -C $SRCDIR/oar-${VERSION} PREFIX=/usr/local node-setup

echo "oar-$VERSION"
