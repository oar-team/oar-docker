FROM oarcluster/node:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify

RUN pip install colmet

ADD sbin /usr/local/sbin
ADD supervisor/colmet-node.conf /etc/supervisor/conf.d/colmet-node.conf

## Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*  && \
    rm -f /etc/ssh/ssh_host_*

CMD ["/usr/local/sbin/init_kvm", "/usr/local/sbin/my_init", "/usr/local/sbin/taillogs"]
