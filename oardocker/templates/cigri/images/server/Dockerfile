FROM oardocker/jessie-server:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

ADD install_cigri.sh /root/install_cigri.sh
RUN chmod +x  /root/install_cigri.sh
