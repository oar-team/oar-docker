FROM oardocker/jessie-base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV COLOR red
RUN echo "export COLOR=red" > /etc/hostname.color

# RUN apt-get update
# RUN apt-get install -y my_packages

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql/

ADD sbin /usr/local/sbin
RUN chmod +x /usr/local/sbin/*

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/*

## systemd services
ADD systemd /etc/systemd/system
RUN chmod 644 /etc/systemd/system/* ; \
    systemctl enable oardocker-postgresql oardocker-server oardocker-resources oardocker-queues

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*
