FROM oardocker/debian8:1.0.4
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV CONTAINER_LIB_PATH /var/lib/container
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes
ENV COLOR green
RUN echo "export COLOR=green" > /etc/hostname.color

# RUN apt-get update
# RUN apt-get install -y my_packages

## configure sshd daemon:
RUN mkdir -p $CONTAINER_LIB_PATH
RUN mv /etc/ssh/ $CONTAINER_LIB_PATH/ssh ;\
    ln -sf $CONTAINER_LIB_PATH/ssh /etc/ssh ;\
    mkdir -p /var/run/sshd
ADD config/sshd_config /etc/ssh/sshd_config

## add helpers scripts:
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

RUN echo "/var/log/auth.log" >> $CONTAINER_LIB_PATH/log2watch.txt ;\
    echo "/var/log/my_init.d.log" >> $CONTAINER_LIB_PATH/log2watch.txt

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*

CMD ["/usr/local/sbin/oardocker_init"]
