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
    libtie-ixhash-perl libwww-perl apache2 libcgi-fast-perl ruby1.9

## Install chandler requirements
RUN gem install rest-client naturalsort rspec

# Install php
RUN apt-get install -y php5 php5-pgsql php5-mcrypt php-apc

# Install phppgadmin
RUN apt-get install -y phppgadmin

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
