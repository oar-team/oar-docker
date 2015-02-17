FROM ubuntu:precise
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV CONTAINER_LIB_PATH /var/lib/container
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes
ENV COLOR green
RUN echo "export COLOR=green" > /etc/hostname.color

## Enable Ubuntu Universe and Multiverse.
RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse" > /etc/apt/sources.list ;\
    echo "deb http://archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse" >> /etc/apt/sources.list ;\
    echo "deb http://archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse" >> /etc/apt/sources.list ;\
    apt-get update

## Prepare and install packages
## core packages
RUN apt-get install -y \
    sudo less vim nano bash-completion apt-transport-https \
    ca-certificates psmisc openssh-client curl wget python supervisor \
    iptables socat ifupdown locales isc-dhcp-client net-tools iproute \
    qemu-kvm net-tools bridge-utils uml-utilities perl \
    perl-base build-essential taktuk libdbi-perl libsort-versions-perl \
    libdbd-pg-perl postgresql-client inetutils-ping rsyslog git \
    tmux openssh-server netcat unionfs-fuse

## frontend dependencies
RUN apt-get install -y \
    libsort-naturally-perl libjson-perl libyaml-perl libappconfig-perl \
    libtie-ixhash-perl libwww-perl libgd-ruby1.8 apache2-mpm-prefork \
    libcgi-fast-perl libapache2-mod-fastcgi librestclient-ruby1.8 \
    libdbd-pg-ruby1.8 ruby1.8 ruby1.8-dev rubygems1.8 \
    php5 libapache2-mod-php5 php5-mcrypt php5-pgsql phppgadmin

## server dependencies
RUN apt-get install -y postgresql


## Python install
RUN apt-get install -y python-pip python-dev libpq-dev
RUN pip install -U virtualenv pip
ADD dev-requirements.txt dev-requirements.txt
RUN pip install -I -r dev-requirements.txt && rm dev-requirements.txt

## Old Python versions
RUN apt-get install -y python-software-properties
RUN add-apt-repository -y ppa:fkrull/deadsnakes
RUN apt-get update -q
RUN apt-get install -y python2.6-dev python3.2-dev python3.3-dev python3.4-dev pypy-dev

RUN apt-get install -y libpq-dev
ADD dev-requirements.txt dev-requirements.txt
RUN pip install -I -r dev-requirements.txt && rm dev-requirements.txt


## Fix locales
RUN test ! -f /etc/locale.gen || sed -i 's/^# fr_FR/fr_FR/' /etc/locale.gen
RUN locale-gen fr_FR.utf8
RUN update-locale LANG=fr_FR.utf8

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

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh
