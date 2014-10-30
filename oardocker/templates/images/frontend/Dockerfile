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
    libtie-ixhash-perl libwww-perl nginx libcgi-fast-perl ruby1.9 fcgiwrap \
    nginx

## Install chandler requirements
RUN gem install rest-client naturalsort rspec

# Install php
RUN apt-get install -y php5 php5-fpm php5-pgsql php5-mcrypt php-apc

# Install phppgadmin
RUN apt-get install -y phppgadmin

## Scripts
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

ADD motd /etc/motd

RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Configure cgi + http
ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx-default-site /etc/nginx/sites-enabled/default
RUN cp /usr/share/doc/fcgiwrap/examples/nginx.conf /etc/nginx/fcgiwrap.conf

ADD config/php-fpm.conf /etc/php5/fpm/php-fpm.conf

## Configure services.
ADD circus/oar_web.ini /etc/circus.d/oar_web.ini


## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

EXPOSE 22
EXPOSE 80
