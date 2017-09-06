FROM oardocker/stretch-server:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

RUN chown -R root:root /root
RUN chmod a+rw /etc/oar/oar.conf
RUN touch /var/log/oar.log
RUN chmod a+rw /var/log/oar.log

# oardocker-resources.services blocks systemd (only at init) 
RUN systemctl disable oardocker-resources

ADD configure_oar.sh /tmp/configure_oar.sh
RUN /bin/bash /tmp/configure_oar.sh

RUN rm -rf /tmp/* /root/.cache
