FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"
ENV COLOR yellow
RUN echo "export COLOR=yellow" > /etc/hostname.color

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/*
