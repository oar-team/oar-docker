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

## Php5
ADD config/php5.conf /etc/php5/fpm/pool.d/oardocker.conf
#RUN chown www-data:www-data /etc/php5/fpm/pool.d/oardocker.conf

## systemd services
ADD systemd /etc/systemd/system
RUN chmod 644 /etc/systemd/system/* ; \
    systemctl enable oardocker-apache.service oardocker-fcgi.socket

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*

EXPOSE 80
EXPOSE 9090
