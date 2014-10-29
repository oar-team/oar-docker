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
    libtie-ixhash-perl libwww-perl apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi ruby1.9

## Install chandler requirements
RUN gem install restclient naturalsort rspec


# Install php
RUN apt-get install -y php5 libapache2-mod-php5 php5-mcrypt php5-pgsql

# Install phppgadmin
RUN apt-get install -y phppgadmin

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
