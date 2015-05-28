FROM oardocker/wheezy-base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"
ENV COLOR yellow
RUN echo "export COLOR=yellow" > /etc/hostname.color

# RUN apt-get update
# RUN apt-get install -y my_packages

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh && rm -rf /tmp/*
