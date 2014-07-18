FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

RUN echo "export COLOR=yellow" > /etc/hostname.color

ADD sbin/ /sbin/
RUN echo "#!/bin/bash\nsudo /sbin/taillogs" > /usr/local/bin/taillogs
RUN chmod +x /usr/local/bin/taillogs

ADD supervisor /etc/supervisor/conf.d

## Install OAR node
RUN mkdir -p /tmp/oar
ADD oar-tarball.tar.gz /tmp/oar
ADD version.txt /tmp/oar/version.txt

RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local node-build
RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local node-install
RUN make -C /tmp/oar/oar-$(cat /tmp/oar/version.txt) PREFIX=/usr/local node-setup

## Cleanup
RUN rm -rf /tmp/*

CMD ["/sbin/my_init", "/sbin/taillogs"]
