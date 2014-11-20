FROM debian:jessie
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV CONTAINER_LIB_PATH /var/lib/container
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes
ENV COLOR green
RUN echo "export COLOR=green" > /etc/hostname.color

## enable jessie backports:
RUN echo "deb http://http.debian.net/debian jessie main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://http.debian.net/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org jessie/updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://http.debian.net/debian jessie-backports main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update -q

## Prepare and install packages
## core packages
RUN apt-get install -y \
    debian-keyring sudo less vim nano bash-completion apt-transport-https \
    ca-certificates psmisc openssh-client curl wget python \
    iptables socat ifupdown locales isc-dhcp-client net-tools iproute2 \
    qemu-kvm linux-image-amd64 net-tools bridge-utils uml-utilities perl \
    perl-base build-essential taktuk libdbi-perl libsort-versions-perl \
    libdbd-pg-perl postgresql-client inetutils-ping rsyslog git \
    tmux openssh-server netcat unionfs-fuse procps rsync

## frontend dependencies
RUN apt-get install -y \
    libsort-naturally-perl libjson-perl libyaml-perl libappconfig-perl \
    libtie-ixhash-perl libwww-perl apache2 apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi php5 libapache2-mod-php5 \
    php5-mcrypt php5-pgsql phppgadmin perl php5-cli

## colmet dependencies
RUN apt-get install -y python-dev python-zmq python-pip python-tables  \
    python-h5py python-pyinotify inotify-tools

## server dependencies
RUN apt-get install -y postgresql python-psycopg2

## Python
RUN pip install -I pip ipdb grin jedi

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

## configure skel:
COPY skel /etc/skel
RUN chmod 700 /etc/skel/.ssh ;\
    chmod 600 /etc/skel/.ssh/* ;\
    rsync -ah /etc/skel/ /root/

## add user docker
RUN useradd -m docker -s /bin/bash && \
    echo -n 'docker:docker' | chpasswd && \
    usermod -G sudo docker

## enable_passwordless_sudo:
RUN cp /etc/sudoers /etc/sudoers.orig && \
    sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

## fix ssh forwarding agent with sudo:
RUN echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" > /etc/sudoers.d/root_ssh_agent && \
    chmod 0440 /etc/sudoers.d/root_ssh_agent

RUN rm -rf /tmp/* /var/tmp/*

RUN echo "/var/log/auth.log" >> $CONTAINER_LIB_PATH/log2watch.txt ;\
    echo "/var/log/my_init.d.log" >> $CONTAINER_LIB_PATH/log2watch.txt

CMD ["/usr/local/sbin/oardocker_init"]
