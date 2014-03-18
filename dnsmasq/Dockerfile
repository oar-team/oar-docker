FROM debian:wheezy
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

VOLUME [ "/etc/dnsmasq.d" ]

RUN apt-get update
RUN apt-get install -y dnsmasq-base inotify-tools procps

RUN echo "user=root" > /etc/dnsmasq.conf
RUN echo "domain-needed" >> /etc/dnsmasq.conf
RUN echo "expand-hosts" >> /etc/dnsmasq.conf
RUN echo "bogus-priv" >> /etc/dnsmasq.conf
RUN echo "domain=oarcluster"  >> /etc/dnsmasq.conf
RUN echo "listen-address=__LOCAL_IP__" >> /etc/dnsmasq.conf
RUN echo "resolv-file=/etc/resolv.dnsmasq.conf" >> /etc/dnsmasq.conf
RUN echo "conf-dir=/etc/dnsmasq.d"  >> /etc/dnsmasq.conf

# Opendns
RUN echo "nameserver 208.67.222.222" > /etc/resolv.dnsmasq.conf
RUN echo "nameserver 208.67.220.220" > /etc/resolv.dnsmasq.conf
# Google
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.dnsmasq.conf
RUN echo "nameserver 8.8.4.4" >> /etc/resolv.dnsmasq.conf

RUN apt-get autoremove -y && apt-get autoclean -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*

ADD dnsmasq_cmd /sbin/dnsmasq_cmd

CMD ["/sbin/dnsmasq_cmd"]
