#!/bin/sh
set -e

# Ugly hack with docker >=1.6.0...
if ! grep -q oardocker /etc/hosts > /dev/null; then
    echo "Fixing /etc/hosts..."
    umount /etc/hosts
fi
