FROM oarcluster/node
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify

RUN pip install colmet

ADD sbin /sbin
ADD supervisor /etc/supervisor/conf.d

## Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*  && \
    rm -f /etc/ssh/ssh_host_*

CMD ["/sbin/init_kvm", "/sbin/my_init", "/sbin/taillogs"]
