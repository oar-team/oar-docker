FROM oarcluster/server
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify
RUN wget -q https://github.com/oar-team/colmet/archive/master.tar.gz -O /tmp/colmet-master.tar.gz
RUN tar xf /tmp/colmet-master.tar.gz -C /tmp/
RUN pip install /tmp/colmet-master

ADD sbin /sbin

## Supervisor
ADD supervisor/ /etc/supervisor/conf.d/
## Use cgroup for job managment
ADD etc/oar/job_resource_manager.pl /etc/oar/job_resource_manager.pl

## Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*  && \
    rm -f /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
