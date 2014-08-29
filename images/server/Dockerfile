FROM oarcluster/base:0.3
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
RUN echo "export COLOR=red" > /etc/hostname.color

## Prepare packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    postgresql postgresql-client

ADD etc/oar/job_resource_manager.pl /etc/oar/job_resource_manager.pl

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql/

## Setup apache2 daemon.
ADD supervisor/oar-server.conf /etc/supervisor/conf.d/oar-server.conf
ADD supervisor/postgresql.conf /etc/supervisor/conf.d/postgresql.conf

ADD sbin /usr/local/sbin
RUN echo "#!/bin/bash\nsudo /usr/local/sbin/taillogs" > /usr/local/bin/taillogs
RUN chmod +x /usr/local/bin/taillogs

## Install OAR server
RUN mkdir -p /tmp/oar
ADD oar-tarball.tar.gz /tmp/oar
ADD version.txt /tmp/oar/version.txt

RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local server-build
RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local server-install
RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local server-setup

RUN test ! -f /usr/local/share/oar/oar-server/init.d/oar-server || \
    ( cat /usr/local/share/oar/oar-server/init.d/oar-server > /etc/init.d/oar-server && \
    chmod +x  /etc/init.d/oar-server )

RUN test ! -f /usr/local/share/doc/oar-server/examples/init.d/oar-server || \
    ( cat /usr/local/share/doc/oar-server/examples/init.d/oar-server > /etc/init.d/oar-server && \
    chmod +x  /etc/init.d/oar-server )

RUN test ! -f /usr/local/share/oar/oar-server/default/oar-server || \
    cat /usr/local/share/oar/oar-server/default/oar-server > /etc/default/oar-server

RUN test ! -f /usr/local/share/doc/oar-server/examples/default/oar-server || \
    cat /usr/local/share/doc/oar-server/examples/default/oar-server > /etc/default/oar-server

RUN chown oar:oar /etc/oar/job_resource_manager.pl && \
    chmod +x /etc/oar/job_resource_manager.pl

ADD configure_server.sh /tmp/configure_server.sh
RUN /tmp/configure_server.sh

## Cleanup
RUN apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*  && \
    rm -f /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs"]
