FROM oarcluster/base
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && apt-get install -y nfs-kernel-server runit inotify-tools -qq
RUN mkdir -p /data

RUN echo "/data *(rw,all_squash,anonuid=1000,anongid=1000,async,no_subtree_check)" >> /etc/exports

ADD sbin /sbin
ADD supervisor/ /etc/supervisor/conf.d/

VOLUME /data

EXPOSE 111/udp 2049/tcp

CMD ["/sbin/my_init"]
