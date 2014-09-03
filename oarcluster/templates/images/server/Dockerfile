FROM oarcluster/base:latest
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

## Setup supervisor services.
ADD supervisor/oar-server.conf /etc/supervisor/conf.d/oar-server.conf
ADD supervisor/postgresql.conf /etc/supervisor/conf.d/postgresql.conf

ADD sbin /usr/local/sbin
RUN chmod +x /usr/local/sbin/*

ADD postinstall.sh /root/postinstall.sh
RUN chmod +x /root/postinstall.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs"]
