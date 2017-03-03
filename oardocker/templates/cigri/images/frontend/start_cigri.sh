#!/bin/bash                                                                            

/etc/init.d/oidentd start
mkdir -p /var/run/cigri
chown -R cigri /var/run/cigri
su - cigri -c "cd /usr/local/share/cigri && /usr/local/share/cigri/modules/almighty.rb"
