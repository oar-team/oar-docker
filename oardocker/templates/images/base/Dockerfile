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

## dns ndependencies
RUN apt-get install -y dnsmasq-base inotify-tools procps

## server dependencies
RUN apt-get install -y postgresql python-psycopg2

## add user docker
RUN useradd -m docker -s /bin/bash && \
    echo -n 'docker:docker' | chpasswd && \
    usermod -G sudo docker

## enable_passwordless_sudo:
RUN cp /etc/sudoers /etc/sudoers.orig && \
    sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

## Install init process.
ADD sbin/my_init /usr/local/sbin/my_init
RUN chmod +x /usr/local/sbin/my_init && \
    mkdir -p $CONTAINER_LIB_PATH/my_init.d && \
    mkdir -p $CONTAINER_LIB_PATH/container_environment && \
    touch $CONTAINER_LIB_PATH/container_environment.sh && \
    touch $CONTAINER_LIB_PATH/container_environment.json && \
    chmod 700 $CONTAINER_LIB_PATH/container_environment && \
    chmod 600 $CONTAINER_LIB_PATH/container_environment.sh && \
    chmod 600 $CONTAINER_LIB_PATH/container_environment.json

## Configure supervisor
RUN mkdir -p $CONTAINER_LIB_PATH/supervisor/conf.d && \
    mkdir -p $CONTAINER_LIB_PATH/supervisor/log && \
    rm -rf /etc/supervisor && \
    ln -sf $CONTAINER_LIB_PATH/supervisor /etc/supervisor && \
    ln -sf $CONTAINER_LIB_PATH/supervisor/log /var/log/supervisor
ADD config/supervisord.conf /etc/supervisor/supervisord.conf

## configure sshd daemon:
ADD supervisor/sshd.conf /etc/supervisor/conf.d/sshd.conf
RUN mv /etc/ssh $CONTAINER_LIB_PATH/ssh && \
    ln -sf $CONTAINER_LIB_PATH/ssh /etc/ssh
ADD config/sshd_config /etc/ssh/sshd_config
ADD sbin/sshd /usr/local/sbin/sshd
RUN chmod +x /usr/local/sbin/sshd && \
    mkdir -p /var/run/sshd

## configure rsyslogd daemon:
ADD supervisor/rsyslogd.conf /etc/supervisor/conf.d/rsyslogd.conf

## add helpers scripts:
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

## configure insecure ssh keys:
ADD config/insecure_key.pub $CONTAINER_LIB_PATH/insecure_key.pub
ADD config/insecure_key $CONTAINER_LIB_PATH/insecure_key
RUN chmod +x /usr/local/sbin/enable_insecure_key && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    chown root:root /root/.ssh && \
    chmod 644 $CONTAINER_LIB_PATH/insecure_key* && \
    chown root:root $CONTAINER_LIB_PATH/insecure_key*

RUN pip install ipdb grin

## fix ssh forwarding agent with sudo:
RUN echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" > /etc/sudoers.d/root_ssh_agent && \
    chmod 0440 /etc/sudoers.d/root_ssh_agent

## configure bash:
ADD config/bashrc /home/docker/.bashrc
ADD config/bashrc /root/.bashrc

## configure vim:
ADD config/vimrc /home/docker/.vimrc
ADD config/vimrc /root/.vimrc
RUN update-alternatives --set editor /usr/bin/vim.basic

# Configure Tmux
ADD config/tmux.conf /home/docker/.tmux.conf
ADD config/tmux.conf /root/.tmux.conf

# Configure ssh client
ADD config/sshrc /home/docker/.ssh/rc
ADD config/sshrc /root/.ssh/rc
RUN chmod +x /home/docker/.ssh/rc /root/.ssh/rc

# configure git:
ADD config/gitconfig /home/docker/.gitconfig
ADD config/gitconfig /root/.gitconfig

## fix_permission:
RUN chown -R docker:docker /home/docker

RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs"]
