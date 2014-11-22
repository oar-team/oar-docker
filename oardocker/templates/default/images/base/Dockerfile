FROM debian:wheezy
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV CONTAINER_LIB_PATH /var/lib/container
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes
ENV COLOR green
RUN echo "export COLOR=green" > /etc/hostname.color

## enable wheezy backports:
RUN echo "deb http://http.debian.net/debian wheezy main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://http.debian.net/debian wheezy-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org wheezy/updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://http.debian.net/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update -q

## Prepare and install packages
## core packages
RUN apt-get install -y \
    debian-keyring sudo less vim nano bash-completion apt-transport-https \
    ca-certificates psmisc openssh-client curl wget python supervisor \
    iptables socat ifupdown locales isc-dhcp-client net-tools iproute \
    qemu-kvm linux-image-amd64 net-tools bridge-utils uml-utilities perl \
    perl-base build-essential taktuk libdbi-perl libsort-versions-perl \
    libdbd-pg-perl postgresql-client inetutils-ping rsyslog git \
    tmux/wheezy-backports openssh-server netcat unionfs-fuse

## frontend dependencies
RUN apt-get install -y \
    libsort-naturally-perl libjson-perl libyaml-perl libappconfig-perl \
    libtie-ixhash-perl libwww-perl libgd-ruby1.8 apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi librestclient-ruby1.8 \
    libdbd-pg-ruby1.8 ruby1.8 ruby1.8-dev rubygems1.8 ruby-switch \
    php5 libapache2-mod-php5 php5-mcrypt php5-pgsql phppgadmin

## colmet dependencies
RUN apt-get install -y python-dev python-zmq python-pip python-tables  \
    python-h5py python-pyinotify

## server dependencies
RUN apt-get install -y postgresql python-psycopg2

## Fix locales
RUN test ! -f /etc/locale.gen || sed -i 's/^# fr_FR/fr_FR/' /etc/locale.gen
RUN locale-gen fr_FR.utf8
RUN update-locale LANG=fr_FR.utf8

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
