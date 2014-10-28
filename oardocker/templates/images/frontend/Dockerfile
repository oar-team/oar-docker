FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV COLOR blue
RUN echo "export COLOR=blue" > /etc/hostname.color

## Prepare packages
RUN apt-get update
RUN apt-get install -y \
    libsort-naturally-perl libjson-perl libyaml-perl libappconfig-perl \
    libtie-ixhash-perl libwww-perl libgd-ruby1.8 apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi librestclient-ruby1.8 \
    libdbd-pg-ruby1.8 ruby1.8 rubygems1.8 ruby-switch

RUN ruby-switch --set ruby1.8

# Install php
RUN apt-get install -y php5 libapache2-mod-php5 php5-mcrypt php5-pgsql

# Install phppgadmin
RUN apt-get install -y phppgadmin

## Install chandler
RUN wget -q https://rubygems.org/downloads/naturalsort-1.1.1.gem -O /tmp/naturalsort-1.1.1.gem && \
    wget -q https://rubygems.org/downloads/json-1.8.1.gem -O /tmp/json-1.8.1.gem && \
    gem install /tmp/naturalsort-1.1.1.gem /tmp/json-1.8.1.gem --no-ri --no-rdoc

## Scripts
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

## Setup apache2 daemon.
ADD supervisor/apache2.conf /etc/supervisor/conf.d/apache2.conf

ADD motd /etc/motd

RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

EXPOSE 22
EXPOSE 80

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs", "--enable-insecure-key"]
