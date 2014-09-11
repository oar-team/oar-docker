FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"


RUN apt-get update -q
RUN apt-get install -y postgresql dnsmasq-base procps incron

## Setup supervisor services
ADD supervisor/ /etc/supervisor/conf.d/

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

## Configure database
# configure PostgreSQL to listen for remote connections
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/9.1/main/postgresql.conf
# configure PostgreSQL to accept remote connections (from any host):
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/9.1/main/pg_hba.conf
# set insecure postgres password
RUN service postgresql start && \
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs", "--enable-insecure-key"]
