FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

## Prepare packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    perl perl-base openssh-client openssh-server build-essential

## Install OAR node
RUN wget -q https://github.com/oar-team/oar/archive/$OAR_VERSION.tar.gz -O /tmp/oar-$OAR_VERSION.tar.gz
RUN tar xf /tmp/oar-$OAR_VERSION.tar.gz -C /tmp/

RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local node-build
RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local node-install
RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local node-setup

## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

ADD oar_node_cmd /sbin/oar_node_cmd
RUN chmod +x /sbin/oar_node_cmd

CMD ["/sbin/my_init", "/sbin/oar_node_cmd"]
