FROM oardocker/jessie-server:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

ADD configure_cigri.sh /tmp/configure_cigri.sh
RUN /bin/bash /tmp/configure_cigri.sh
