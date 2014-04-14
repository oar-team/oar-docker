FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

## Prepare packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    perl perl-base openssh-client openssh-server libdbi-perl \
    libsort-versions-perl taktuk build-essential \
    postgresql postgresql-client libdbd-pg-perl

## Install OAR node
RUN wget -q https://github.com/oar-team/oar/archive/$OAR_VERSION.tar.gz -O /tmp/oar-$OAR_VERSION.tar.gz
RUN tar xf /tmp/oar-$OAR_VERSION.tar.gz -C /tmp/

RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local server-build
RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local server-install
RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local server-setup

ADD job_resource_manager.pl /etc/oar/job_resource_manager.pl

ADD configure_server.sh /tmp/configure_server.sh
RUN /tmp/configure_server.sh


## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

## Install the postgresql daemon.
RUN mkdir -p /etc/service/postgresql
ADD runit/postgresql /etc/service/postgresql/run

## Setup apache2 daemon.
ADD supervisor/postgresql.conf /etc/supervisor/conf.d/postgresql.conf

EXPOSE 22

ADD oar_server_cmd /sbin/oar_server_cmd

ENTRYPOINT ["/sbin/my_init", "/sbin/oar_server_cmd"]
