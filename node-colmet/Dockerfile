FROM oarcluster/node
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify
RUN wget -q --no-check-certificate https://github.com/oar-team/colmet/archive/master.tar.gz -O /tmp/colmet-master.tar.gz
RUN tar xf /tmp/colmet-master.tar.gz -C /tmp/
RUN pip install /tmp/colmet-master

ADD sbin /sbin
ADD etc /etc

# RUN cp /etc/supervisor/conf.d/oar-node.conf /tmp/oar-node.conf && \
#     rm /etc/supervisor/conf.d/* && \
#     cp /tmp/oar-node.conf /etc/supervisor/conf.d/oar-node.conf

## Cleanup
RUN apt-get remove -y build-essential && apt-get autoremove -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -f /etc/ssh/ssh_host_*

CMD ["/sbin/my_init", "/sbin/showlog.sh"]
