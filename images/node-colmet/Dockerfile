FROM oarcluster/node
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify

RUN wget -q --no-check-certificate https://github.com/oar-team/colmet/archive/master.tar.gz -O /tmp/colmet-master.tar.gz && \
    tar xf /tmp/colmet-master.tar.gz -C /tmp/ && \
    pip install /tmp/colmet-master

ADD sbin /sbin
ADD supervisor /etc/supervisor/conf.d

CMD ["/sbin/init_kvm", "/sbin/my_init", "/sbin/cmd.sh"]
