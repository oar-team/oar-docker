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
    libtie-ixhash-perl libwww-perl apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi 

# Install php
RUN apt-get install -y php5 libapache2-mod-php5 php5-mcrypt php5-pgsql

# Install phppgadmin
RUN apt-get install -y phppgadmin

ADD motd /etc/motd

RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Configure log
RUN echo "/var/log/apache2/error.log" >> $CONTAINER_LIB_PATH/log2watch.txt ;\
    echo "/var/log/apache2/access.log" >> $CONTAINER_LIB_PATH/log2watch.txt

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*

EXPOSE 22
EXPOSE 80
