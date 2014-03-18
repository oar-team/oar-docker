FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

## Prepare packages
RUN apt-get update
RUN apt-get install -y \
    perl perl-base openssh-client openssh-server \
    libsort-versions-perl libsort-naturally-perl taktuk build-essential \
    postgresql-client libdbd-pg-perl libjson-perl libyaml-perl \
    libgd-ruby1.8 libdbi-perl libtie-ixhash-perl libappconfig-perl \
    php5-pgsql libapache2-mod-php5 libwww-perl apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi \
    ruby-rest-client libdbd-pg-ruby ruby-rest-client

## Install OAR frontend node
RUN wget -q https://github.com/oar-team/oar/archive/$OAR_VERSION.tar.gz -O /tmp/oar-$OAR_VERSION.tar.gz
RUN tar xf /tmp/oar-$OAR_VERSION.tar.gz -C /tmp/

RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local user-build tools-build
RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local user-install drawgantt-install monika-install www-conf-install api-install tools-install
RUN make -C /tmp/oar-$OAR_VERSION/ PREFIX=/usr/local user-setup drawgantt-setup monika-setup www-conf-setup api-setup tools-setup

ADD configure_frontend.sh /tmp/configure_frontend.sh
RUN /tmp/configure_frontend.sh

## Install chandler
RUN wget -q https://rubygems.org/downloads/naturalsort-1.1.1.gem -O /tmp/naturalsort-1.1.1.gem
RUN gem install /tmp/naturalsort-1.1.1.gem
ADD chandler.rb /usr/local/bin/chandler
RUN chmod +x /usr/local/bin/chandler

## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

## Setup apache2 daemon.
RUN mkdir -p /etc/service/apache2
ADD runit/apache2 /etc/service/apache2/run

ADD motd /etc/motd
RUN sed -i s/__OAR_VERSION__/$OAR_VERSION/ /etc/motd

RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

EXPOSE 22
EXPOSE 80

ENTRYPOINT ["/sbin/my_init"]
