FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && apt-get install -y nfs-common inotify-tools -qq

ADD mount_nfs_data.sh /etc/my_init.d/mount_nfs_data.sh
RUN chmod +x /etc/my_init.d/mount_nfs_data.sh

CMD ["/sbin/my_init"]
