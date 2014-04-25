FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

## Prepare packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    perl perl-base openssh-client openssh-server build-essential


## Install OAR node
ADD version.txt /tmp/version.txt
RUN wget -q https://github.com/oar-team/oar/archive/$(cat /tmp/version.txt).tar.gz -O /tmp/oar-$(cat /tmp/version.txt).tar.gz
RUN tar xf /tmp/oar-$(cat /tmp/version.txt).tar.gz -C /tmp/

RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-build
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-install
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-setup

ADD sbin/oar-node /sbin/oar-node
ADD supervisor /etc/supervisor/conf.d
ADD cmd.sh /sbin/cmd.sh

## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
