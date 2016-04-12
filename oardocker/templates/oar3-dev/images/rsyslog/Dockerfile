FROM oardocker/jessie-rsyslog:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service
