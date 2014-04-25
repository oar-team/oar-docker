FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

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

## Download
## Install OAR frontend node
ADD version.txt /tmp/version.txt
RUN wget -q https://github.com/oar-team/oar/archive/$(cat /tmp/version.txt).tar.gz -O /tmp/oar-$(cat /tmp/version.txt).tar.gz
RUN tar xf /tmp/oar-$(cat /tmp/version.txt).tar.gz -C /tmp/

RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local user-build tools-build
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local user-install drawgantt-svg-install monika-install www-conf-install api-install tools-install
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local user-setup drawgantt-svg-setup monika-setup www-conf-setup api-setup tools-setup

ADD configure_frontend.sh /tmp/configure_frontend.sh
RUN /tmp/configure_frontend.sh

## Install chandler
RUN wget -q https://rubygems.org/downloads/naturalsort-1.1.1.gem -O /tmp/naturalsort-1.1.1.gem
RUN wget -q https://rubygems.org/downloads/json-1.8.1.gem -O /tmp/json-1.8.1.gem
RUN gem install /tmp/naturalsort-1.1.1.gem /tmp/json-1.8.1.gem --no-ri --no-rdoc
ADD chandler.rb /usr/local/bin/chandler
RUN chmod +x /usr/local/bin/chandler

## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

## Setup apache2 daemon.
ADD supervisor/apache2.conf /etc/supervisor/conf.d/apache2.conf

ADD motd /etc/motd
RUN sed -i s/__OAR_VERSION__/$(cat /tmp/version.txt)/ /etc/motd

RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

ADD cmd.sh /sbin/cmd.sh

EXPOSE 22
EXPOSE 80

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
