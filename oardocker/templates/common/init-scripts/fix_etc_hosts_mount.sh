#!/bin/sh
set -e

umount -f /etc/hosts
mv /etc/hosts /etc/hosts.docker
ln -s /etc/hosts.oardocker /etc/hosts

# # Ugly hack with docker >=1.6.0...
# if ! grep -q oardocker /etc/hosts > /dev/null; then
#     echo "Fixing /etc/hosts..."
#     umount /etc/hosts
# fi
