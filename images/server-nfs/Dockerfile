FROM oarcluster/nfs-client
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

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql

## Setup apache2 daemon.
ADD supervisor/ /etc/supervisor/conf.d/

ADD cmd.sh /sbin/cmd.sh

## Cleanup
RUN apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*  && \
    rm -f /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
