#!/bin/bash
set -e

echo "Mounting COW volumes..."
while read cow_volume; do
    # COW_PATH => the final mountpoint
    # RO_PATH => the read only docker mount
    # RW_PATH => contained only local changes layer
    IFS=':' read COW_PATH RO_PATH <<< "$cow_volume"
    if [ -n "${COW_PATH}" ]; then
        mkdir -p "$COW_PATH"
        RW_PATH=$(mktemp -d --tmpdir oardocker_mout.XXXXXXXX)
        unionfs-fuse -o cow -o allow_other,default_permissions,use_ino,suid,dev,nonempty "$RW_PATH"=RW:"$RO_PATH"=RO "$COW_PATH"
        chmod --reference="$RO_PATH" "$COW_PATH"
        chown --reference="$RO_PATH" "$COW_PATH"
        echo " -> $COW_PATH "
    fi
done </var/lib/container/cow_volumes
