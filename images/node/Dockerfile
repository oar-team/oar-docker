FROM oarcluster/base:0.2
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

RUN echo "export COLOR=yellow" > /etc/hostname.color

ADD sbin/ /usr/local/sbin/
RUN echo "#!/bin/bash\nsudo /usr/local/sbin/taillogs" > /usr/local/bin/taillogs
RUN chmod +x /usr/local/bin/taillogs

ADD supervisor/oar-node.conf /etc/supervisor/conf.d/oar-node.conf

## Install OAR node
RUN mkdir -p /tmp/oar
ADD oar-tarball.tar.gz /tmp/oar
ADD version.txt /tmp/oar/version.txt

RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local node-build
RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local node-install
RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local node-setup

## Cleanup
RUN rm -rf /tmp/*

CMD ["/usr/local/sbin/my_init", "/sbin/taillogs"]
