#!/bin/bash
set -e

echo "Set replace some oar-v2 cli by their oar-v3 equivalent: oarsub"
mv /usr/local/lib/oar/oarsub /usr/local/lib/oar/oarsub2
ln -s /usr/local/bin/oarsub3 /usr/local/lib/oar/oarsub
