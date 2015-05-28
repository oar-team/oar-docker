FROM oardocker/wheezy-base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV COLOR red
RUN echo "export COLOR=red" > /etc/hostname.color

# RUN apt-get update
# RUN apt-get install -y my_packages

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql/

ADD sbin /usr/local/sbin
RUN chmod +x /usr/local/sbin/*

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Configure log
RUN echo "/var/log/oar.log" >> $CONTAINER_LIB_PATH/log2watch.txt

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*

EXPOSE 22
