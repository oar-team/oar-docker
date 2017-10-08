#!/bin/bash

# Oar property "cluster" creation
ssh server "oarproperty -c -a cluster" 

# Cigri clusters configuration
cd /root/cigri
./sbin/new_cluster.rb tchernobyl http://frontend:6668/oarapi-unsecure/ cert oardocker oardocker '' tchernobyl oar2_5 core 100 "cluster='tchernobyl'"
./sbin/new_cluster.rb threemile http://frontend:6668/oarapi-unsecure/ cert oardocker oardocker '' threemile oar2_5 core 10 "cluster='threemile'"
./sbin/new_cluster.rb fukushima http://frontend:6668/oarapi-unsecure/ cert oardocker oardocker '' fukushima oar2_5 core 50 "cluster='fukushima'"

# OAR customisation
oarnodesetting -a -h node1 -p core=4 -p cpuset=0 -p cpu=4
oarnodesetting -a -h node1 -p core=5 -p cpuset=0 -p cpu=5
oarnodesetting -a -h node1 -p core=6 -p cpuset=0 -p cpu=6
oarnodesetting -a -h node2 -p core=7 -p cpuset=0 -p cpu=7
oarnodesetting -a -h node2 -p core=8 -p cpuset=0 -p cpu=8
oarnodesetting -a -h node2 -p core=9 -p cpuset=0 -p cpu=9
oarnodesetting -a -h node3 -p core=10 -p cpuset=0 -p cpu=10
oarnodesetting -a -h node3 -p core=11 -p cpuset=0 -p cpu=11
oarnodesetting -a -h node3 -p core=12 -p cpuset=0 -p cpu=12
oarnodesetting -p cluster=threemile --sql "network_address='node1'"
oarnodesetting -p cluster=tchernobyl --sql "network_address='node2'"
oarnodesetting -p cluster=fukushima --sql "network_address='node3'"
