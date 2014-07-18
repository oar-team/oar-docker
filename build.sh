#!/bin/bash
set -o errexit

TARBALL=$1
DOCKER=${DOCKER:-docker}
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
NODES=("frontend" "node" "server")
TMPDIR=$(mktemp -d --tmpdir docker-oarcluster.XXXXXXXX)


fail() {
    echo $@ 1>&2
    rm -rf $TMPDIR
    exit 1
}

$DOCKER 2> /dev/null || fail "error: Docker ($DOCKER) executable no found. Make sure Docker is installed and/or use the DOCKER variable to set Docker executable."

[ -n "$TARBALL" ] || fail "error: You must provide a URL to a OAR tarball"
[ -r "$TARBALL" ] && TARBALL=file://$(readlink -m $TARBALL)

curl $TARBALL -o $TMPDIR/oar-tarball.tar.gz || fail "error: failed to fetch oar tarball at $TARBALL"
VERSION=$(tar xfz $TMPDIR/oar-tarball.tar.gz --wildcards "*/sources/core/common-libs/lib/OAR/Version.pm" --to-command "grep -e 'my \$OARVersion'" | sed -e 's/^[^"]\+"\(.\+\)";$/\1/')
[ -n "${VERSION}" ] || fail "error: fail to retrieve OAR version"

. $BASEDIR/clean.sh


# forward OAR version if necessary
for image in "${NODES[@]}"; do
    if [ -f $BASEDIR/images/$image/oar-tarball.tar.gz ]; then
        NEW_MD5=$(md5sum $TMPDIR/oar-tarball.tar.gz | awk '{print $1}')
        OLD_MD5=$(md5sum $BASEDIR/images/$image/oar-tarball.tar.gz | awk '{print $1}')
        if [ ! "$NEW_MD5" == "$OLD_MD5" ]; then
            echo "$VERSION" > $BASEDIR/images/$image/version.txt
            cp $TMPDIR/oar-tarball.tar.gz $BASEDIR/images/$image/
        fi
    else
        echo "$VERSION" > $BASEDIR/images/$image/version.txt
        cp $TMPDIR/oar-tarball.tar.gz $BASEDIR/images/$image/
    fi
done

rm -rf $TMPDIR

$DOCKER build --rm -t oarcluster/dnsmasq $BASEDIR/images/dnsmasq/

for image in "${NODES[@]}"; do
    $DOCKER build --rm -t oarcluster/$image:${VERSION} $BASEDIR/images/$image/
    $DOCKER tag oarcluster/$image:${VERSION} oarcluster/$image:latest
done
$DOCKER images | grep "<none>" | awk '{print $3}' | xargs -I {} $DOCKER rmi -f {}
