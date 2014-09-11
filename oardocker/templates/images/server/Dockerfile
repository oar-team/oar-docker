FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV COLOR red
RUN echo "export COLOR=red" > /etc/hostname.color

## Prepare packages
RUN apt-get update -q
RUN apt-get install -y --no-install-recommends postgresql-client

ADD etc/oar/job_resource_manager.pl /etc/oar/job_resource_manager.pl

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql/

## Setup supervisor services.
ADD supervisor/oar-server.conf /etc/supervisor/conf.d/oar-server.conf

ADD sbin /usr/local/sbin
RUN chmod +x /usr/local/sbin/*

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs", "--enable-insecure-key"]
