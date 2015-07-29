FROM oardocker/jessie-cigri-base:latest
MAINTAINER Bruno Bzeznik "bruno.bzeznik@imag.fr"

ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV COLOR blue
RUN echo "export COLOR=blue" > /etc/hostname.color

RUN apt-get update
RUN apt-get install -y apache2-suexec oidentd libdbd-pg-ruby ruby-dbi ruby-json libapache2-mod-passenger
RUN gem install sinatra rack-test xmpp4r

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

## Create the cigri user
RUN useradd -r -c "Cigri server" -s /bin/bash -m -d /var/lib/cigri cigri

EXPOSE 22
EXPOSE 80
