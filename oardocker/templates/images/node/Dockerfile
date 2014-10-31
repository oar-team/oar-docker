FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"
ENV COLOR yellow
RUN echo "export COLOR=yellow" > /etc/hostname.color

ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*

ADD circus/oar_node.ini /etc/circus.d/oar_node.ini

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*
