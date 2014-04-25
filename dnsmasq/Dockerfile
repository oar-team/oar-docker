FROM oarcluster/base
MAINTAINER Salem Harrache "salem.harrache@inria.fr"


RUN apt-get update && apt-get install -y dnsmasq-base inotify-tools procps

RUN echo "user=root" > /etc/dnsmasq.conf ; \
    echo "domain-needed" >> /etc/dnsmasq.conf ; \
    echo "expand-hosts" >> /etc/dnsmasq.conf ; \
    echo "bogus-priv" >> /etc/dnsmasq.conf ; \
    echo "domain=oarcluster"  >> /etc/dnsmasq.conf ; \
    echo "listen-address=__LOCAL_IP__" >> /etc/dnsmasq.conf ; \
    echo "resolv-file=/etc/resolv.dnsmasq.conf" >> /etc/dnsmasq.conf ; \
    echo "conf-dir=/etc/dnsmasq.d"  >> /etc/dnsmasq.conf

# Opendns
RUN echo "# Opendns" > /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 208.67.222.222" >> /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 208.67.220.220" >> /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 8.8.8.8" >> /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 8.8.4.4" >> /etc/resolv.dnsmasq.conf

RUN apt-get autoremove -y && apt-get autoclean -y && apt-get clean
RUN rm -rf /tmp/* /var/tmp/*

ADD dnsmasq_cmd /sbin/dnsmasq_cmd

VOLUME [ "/etc/dnsmasq.d" ]

CMD ["/sbin/dnsmasq_cmd"]
