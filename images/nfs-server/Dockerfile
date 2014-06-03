FROM oarcluster/base
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && apt-get install -y nfs-kernel-server runit inotify-tools -qq
RUN mkdir -p /data
RUN chown docker:docker -R /data

RUN echo "/data *(rw,insecure,nohide,async,no_root_squash)" >> /etc/exports


ADD sbin /sbin
ADD supervisor/ /etc/supervisor/conf.d/

VOLUME /data

EXPOSE 111/udp 2049/tcp

CMD ["/sbin/my_init"]
