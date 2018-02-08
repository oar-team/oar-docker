FROM oardocker/stretch-server:base
MAINTAINER Bruno Bzeznik "bruno.bzeznik@imag.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

ADD install_cigri.sh /root/install_cigri.sh
RUN chmod +x  /root/install_cigri.sh
