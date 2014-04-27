FROM oarcluster/node
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify

RUN wget -q --no-check-certificate https://github.com/oar-team/colmet/archive/master.tar.gz -O /tmp/colmet-master.tar.gz && \
    tar xf /tmp/colmet-master.tar.gz -C /tmp/ && \
    pip install /tmp/colmet-master

ADD sbin /sbin
ADD etc /etc

# Disable SELinux
RUN mkdir -p /selinux && echo 0 > /selinux/enforce

# Disable services
RUN chmod -x /etc/init.d/ssh && \
    update-rc.d -f apache2 remove && \
    update-rc.d -f postgresql remove && \
    update-rc.d -f rc.local remove && \
    update-rc.d -f uml-utilities remove && \
    update-rc.d -f umountfs remove && \
    update-rc.d -f umountnfs.sh remove && \
    update-rc.d -f x11-common remove && \
    update-rc.d -f umountroot remove && \
    update-rc.d -f networking remove && \
    update-rc.d -f checkfs.sh remove && \
    update-rc.d -f checkroot-bootclean.sh remove && \
    update-rc.d -f checkroot.sh remove && \
    update-rc.d -f qemu-kvm remove && \
    update-rc.d -f hwclock.sh remove && \
    update-rc.d -f hwclockfirst.sh remove && \
    update-rc.d -f cron remove && \
    update-rc.d -f udev remove

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
