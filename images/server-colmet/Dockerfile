FROM oarcluster/server
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV DEBIAN_FRONTEND noninteractive

## Install colmet
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python-dev python-pip \
    libzmq-dev libhdf5-serial-dev g++

RUN pip install cython colmet -U

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

CMD ["/sbin/my_init", "/sbin/taillogs"]
