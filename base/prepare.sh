#!/bin/bash
set -e
source /build/buildconfig
set -x

## Enable Ubuntu Universe.
perl -pi -e "s/main$/main contrib non-free/" /etc/apt/sources.list
apt-get update

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https ca-certificates

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Upgrade all packages.
echo "initscripts hold" | dpkg --set-selections
apt-get upgrade -y --no-install-recommends

## Fix locale.
$minimal_apt_get_install locales
echo "en_US fr_FR" | tr ' ' '\n' | xargs -I {} sed -i 's/^# {}/{}/' /etc/locale.gen
locale-gen en_US fr_FR
