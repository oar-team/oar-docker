#!/bin/bash
set -e

TARGET="/data"
SRC="/data"

rpcbind &


echo -n "Waiting for nfs-server to become available"
until ssh-keyscan nfs-server | grep ssh-rsa\\\|ssh-dsa &> /dev/null
do
    sleep 1
    echo -n "."
done

mkdir -p /data
echo  "Mount NFS shared folder"
mount -t nfs -o rw,user,auto,intr,hard,noatime,rsize=32768,wsize=32768 nfs-server:/data /data
