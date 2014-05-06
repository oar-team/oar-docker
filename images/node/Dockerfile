FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

# Download oar
ADD version.txt /tmp/version.txt
RUN wget -q https://github.com/oar-team/oar/archive/$(cat /tmp/version.txt).tar.gz -O /tmp/oar-$(cat /tmp/version.txt).tar.gz
RUN tar xf /tmp/oar-$(cat /tmp/version.txt).tar.gz -C /tmp/

## Install OAR node
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-build
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-install
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-setup

ADD sbin/ /sbin/
ADD supervisor /etc/supervisor/conf.d

## Cleanup
RUN rm -rf /tmp/*

CMD ["/sbin/my_init", "/sbin/taillogs"]
