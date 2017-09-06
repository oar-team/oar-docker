FROM oardocker/stretch-base:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

ENV COLOR blue
RUN echo "export COLOR=blue" > /etc/hostname.color

# RUN apt-get update
# RUN apt-get install -y my_packages

ADD motd /etc/motd
RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## systemd services
ADD systemd /etc/systemd/system
RUN chmod 644 /etc/systemd/system/* ; \
    systemctl enable oardocker-apache.service

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*

EXPOSE 80
EXPOSE 9090
