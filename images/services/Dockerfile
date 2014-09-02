FROM oarcluster/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"


RUN apt-get update && apt-get install -y dnsmasq-base procps incron

## Setup apache2 daemon.
ADD supervisor/dnsmasq.conf /etc/supervisor/conf.d/dnsmasq.conf

## Scripts
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*

RUN echo "user=root" > /etc/dnsmasq.conf ; \
    echo "no-daemon"  >> /etc/dnsmasq.conf ; \
    echo "no-dhcp-interface=eth0"  >> /etc/dnsmasq.conf ; \
    echo "no-hosts"  >> /etc/dnsmasq.conf ; \
    echo "addn-hosts=/etc/dnsmasq.d/hosts"  >> /etc/dnsmasq.conf ; \
    echo "listen-address=__LOCAL_IP__" >> /etc/dnsmasq.conf ; \
    echo "resolv-file=/etc/resolv.dnsmasq.conf" >> /etc/dnsmasq.conf

# Opendns
RUN echo "# Opendns" > /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 208.67.222.222" >> /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 208.67.220.220" >> /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 8.8.8.8" >> /etc/resolv.dnsmasq.conf ; \
    echo "nameserver 8.8.4.4" >> /etc/resolv.dnsmasq.conf

RUN echo 'root' >> /etc/incron.allow
ADD incron.root /var/spool/incron/root

RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs"]
