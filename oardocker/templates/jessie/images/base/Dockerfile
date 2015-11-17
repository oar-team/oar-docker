FROM oardocker/debian8:1.3
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV container docker
ENV init /lib/systemd/systemd
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

## configure sshd daemon
ADD config/sshd_config /etc/ssh/sshd_config

## add helpers scripts:
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

## tmpfiles.d — Configuration for creation, deletion and cleaning of volatile and temporary files
ADD config/tmpfiles_oardocker.conf /etc/tmpfiles.d/oardocker.conf

## systemd services
RUN rm -rf /etc/systemd/system/*
ADD systemd /etc/systemd/system
RUN systemctl set-default oardocker.target ; \
    chmod 644 /etc/systemd/system/* ; \
    systemctl enable oardocker-sshd.socket oardocker-fix-mount \
                     oardocker-ssh-keys oardocker-mount-cow \
                     oardocker-remote-log

ADD generate_ssh_keys.sh /tmp/generate_ssh_keys.sh
RUN bash /tmp/generate_ssh_keys.sh

ADD create_users.sh /tmp/create_users.sh
RUN bash /tmp/create_users.sh

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd", "systemd.unit=oar-docker.target"]
