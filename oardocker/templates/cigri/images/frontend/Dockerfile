FROM oardocker/stretch-frontend:base
MAINTAINER Bruno Bzeznik "bruno.bzeznik@imag.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

RUN apt-get update -y
RUN apt-get install -y oidentd ruby-sinatra libapache2-mod-passenger ruby-passenger libpq-dev
RUN gem install xmpp4r rest-client pg ydbi ydbd-pg

ADD install_cigri.sh /root/install_cigri.sh
RUN chmod +x /root/install_cigri.sh
ADD init_cigri.sh /root/init_cigri.sh
RUN chmod +x /root/init_cigri.sh
ADD start_cigri.sh /root/start_cigri.sh
RUN chmod +x /root/start_cigri.sh

RUN useradd -ms /bin/bash cigri
