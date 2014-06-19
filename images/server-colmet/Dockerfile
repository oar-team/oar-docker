FROM oarcluster/server
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python-dev python-zmq python-pip python-tables python-h5py python-pyinotify

RUN pip install colmet

ADD sbin /sbin

## Supervisor
ADD supervisor/ /etc/supervisor/conf.d/
## Use cgroup for job managment
ADD etc/oar/job_resource_manager.pl /etc/oar/job_resource_manager.pl
RUN chown oar:oar /etc/oar/job_resource_manager.pl && \
    chmod +x /etc/oar/job_resource_manager.pl

## Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/*  && \
    rm -f /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/sbin/my_init", "/sbin/taillogs"]
