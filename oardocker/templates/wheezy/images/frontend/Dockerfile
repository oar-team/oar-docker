FROM oardocker/wheezy-base:latest
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

## Install chandler requirements
RUN gem install naturalsort rspec json

## Scripts
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

ADD motd /etc/motd

RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/*

## Configure log
RUN echo "/var/log/apache2/error.log" >> $CONTAINER_LIB_PATH/log2watch.txt ;\
    echo "/var/log/apache2/access.log" >> $CONTAINER_LIB_PATH/log2watch.txt

EXPOSE 22
EXPOSE 80
