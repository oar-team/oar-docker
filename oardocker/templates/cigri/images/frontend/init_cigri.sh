#!/bin/bash

# Oar property "cluster" creation
oarproperty -c -a cluster

# Cigri clusters configuration
cd /root/cigri
./sbin/new_cluster.rb tchernobyl https://frontend/oarapi-secured/ cert oardocker oardocker '' tchernobyl oar2_5 core 100 "cluster='tchernobyl'"
./sbin/new_cluster.rb threemile https://frontend/oarapi-secured/ cert oardocker oardocker '' threemile oar2_5 core 10 "cluster='threemile'"
./sbin/new_cluster.rb fukushima https://frontend/oarapi-secured/ cert oardocker oardocker '' fukushima oar2_5 core 50 "cluster='fukushima'"

# OAR customisation
oarnodesetting -p cluster=threemile --sql "network_address='node1'"
oarnodesetting -p cluster=tchernobyl --sql "network_address='node2'"
oarnodesetting -p cluster=fukushima --sql "network_address='node3'"
