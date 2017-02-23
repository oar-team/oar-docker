FROM oardocker/jessie-frontend:latest
MAINTAINER Bruno Bzeznik "bruno.bzeznik@imag.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

RUN apt-get install -y ruby-dbi libapache2-mod-passenger ruby-passenger

ADD install_cigri.sh /root/install_cigri.sh
RUN chmod +x /root/install_cigri.sh
ADD install_cigri.sh /root/init_cigri.sh
RUN chmod +x /root/init_cigri.sh
