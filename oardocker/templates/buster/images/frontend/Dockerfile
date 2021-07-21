FROM oardocker/buster-base:latest
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
#ADD config/nginx.conf /etc/nginx/nginx.conf
#ADD config/nginx-default-site.conf /etc/nginx/sites-available/default

## Php5
ADD config/php5.conf /etc/php5/fpm/pool.d/oardocker.conf
#RUN chown www-data:www-data /etc/php5/fpm/pool.d/oardocker.conf

## systemd services
ADD systemd /etc/systemd/system
# /usr/sbin/update-rc.d does not work

# Workaround problem with apache2
# apache2.service: Failed to set up mount namespacing: Permission denied
# apache2.service: Failed at step NAMESPACE spawning /usr/sbin/apachectl: Permission denied
# ref: https://forum.proxmox.com/threads/apache2-service-failed-to-set-up-mount-namespacing-permission-denied.56871/post-280885
RUN sed -i -e 's,PrivateTmp=true,PrivateTmp=false\nNoNewPrivileges=yes,g' /lib/systemd/system/apache2.service

RUN chmod 644 /etc/systemd/system/* ; \
    systemctl enable apache2.service
#    systemctl enable apache2.service oardocker-fcgi.socket

RUN cp /etc/systemd/system/oardocker-frontend.target /etc/systemd/system/oardocker.target
 
ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*

EXPOSE 80
EXPOSE 9090
