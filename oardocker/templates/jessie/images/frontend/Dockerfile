FROM oardocker/jessie-base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV COLOR blue
RUN echo "export COLOR=blue" > /etc/hostname.color

# RUN apt-get update
# RUN apt-get install -y my_packages

ADD motd /etc/motd
RUN echo "PrintMotd yes" >> /etc/ssh/sshd_config

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## nginx
ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx-default-site.conf /etc/nginx/sites-available/default


## systemd services
ADD systemd /etc/systemd/system
RUN chmod 644 /etc/systemd/system/* ; \
    systemctl enable oardocker-nginx oardocker-php oardocker-fcgi

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*

EXPOSE 22
EXPOSE 80
EXPOSE 9090
