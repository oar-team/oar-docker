FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

## Prepare packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    postgresql postgresql-client

## Install OAR node
ADD version.txt /tmp/version.txt
RUN wget -q https://github.com/oar-team/oar/archive/$(cat /tmp/version.txt).tar.gz -O /tmp/oar-$(cat /tmp/version.txt).tar.gz
RUN tar xf /tmp/oar-$(cat /tmp/version.txt).tar.gz -C /tmp/

RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local server-build
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local server-install
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local server-setup

ADD etc/oar/job_resource_manager.pl /etc/oar/job_resource_manager.pl

ADD configure_server.sh /tmp/configure_server.sh
RUN /tmp/configure_server.sh

## Install colmet
RUN apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify
RUN wget -q https://github.com/oar-team/colmet/archive/master.tar.gz -O /tmp/colmet-master.tar.gz
RUN tar xf /tmp/colmet-master.tar.gz -C /tmp/
RUN pip install /tmp/colmet-master

## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql

## Setup apache2 daemon.
ADD supervisor/postgresql.conf /etc/supervisor/conf.d/postgresql.conf

EXPOSE 22

ADD cmd.sh /sbin/cmd.sh

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
