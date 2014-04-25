FROM debian:wheezy
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

# Set correct environment variables.
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

ONBUILD ENV DEBIAN_FRONTEND noninteractive
ONBUILD RUN apt-get update

RUN echo "deb http://ftp.fr.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list
RUN echo "deb http://ftp.debian.org/debian/ wheezy-updates main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://security.debian.org/ wheezy/updates main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update

## Install HTTPS support for APT.
RUN apt-get install -y --no-install-recommends apt-transport-https ca-certificates

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
# RUN dpkg-divert --local --rename --add /sbin/initctl
# RUN ln -sf /bin/true /sbin/initctl

## Upgrade all packages.
RUN echo "initscripts hold" | dpkg --set-selections
RUN apt-get upgrade -y --no-install-recommends

## Fix locale.
RUN apt-get install -y --no-install-recommends locales
RUN echo "en_US fr_FR" | tr ' ' '\n' | xargs -I {} sed -i 's/^# {}/{}/' /etc/locale.gen
RUN locale-gen en_US fr_FR

## Often used tools.
RUN apt-get install -y --no-install-recommends curl less nano vim psmisc \
                                               sudo openssh-client wget python

## This tool runs a command as another user and sets $HOME.
ADD sbin/setuser /sbin/setuser
RUN chmod +x /sbin/setuser

## Install init process.
ADD sbin/my_init /sbin/
RUN mkdir -p /etc/my_init.d  && \
    mkdir -p /etc/container_environment && \
    touch /etc/container_environment.sh && \
    touch /etc/container_environment.json && \
    chmod 700 /etc/container_environment && \
    chmod 600 /etc/container_environment.sh /etc/container_environment.json

## Install supervisor and services.
RUN apt-get install -y --no-install-recommends cron supervisor syslog-ng-core openssh-server

## Install init process.
RUN mkdir -p /etc/supervisor/ && mkdir -p /var/log/supervisor/
ADD config/supervisord.conf /etc/supervisor/supervisord.conf
ADD supervisor /etc/supervisor/conf.d

RUN mkdir -p /var/lib/syslog-ng/
ADD sbin/syslog-ng /sbin/syslog-ng
RUN chmod +x /sbin/syslog-ng

## Install the SSH server.
ADD sbin/sshd /sbin/sshd
RUN chmod +x /sbin/sshd && mkdir -p /var/run/sshd
ADD config/sshd_config /etc/ssh/sshd_config

## Add default docker user
RUN useradd --create-home -s /bin/bash docker && \
    adduser docker sudo && \
    echo -n 'docker:docker' | chpasswd && \
    sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

## Install default SSH key for root and app.
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && chown root:root /root/.ssh
ADD config/insecure_key.pub /etc/insecure_key.pub
ADD config/insecure_key /etc/insecure_key
RUN chmod 644 /etc/insecure_key* && chown root:root /etc/insecure_key*
ADD sbin/enable_insecure_key /usr/sbin/enable_insecure_key
RUN chmod +x /usr/sbin/enable_insecure_key


## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
RUN rm -f /etc/cron.daily/standard

# clean
RUN apt-get clean && rm -rf /tmp/* /var/tmp/* && rm -f /etc/ssh/ssh_host_*

CMD ["/sbin/my_init"]
