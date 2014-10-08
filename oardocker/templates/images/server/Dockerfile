FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV OAR_VERSION 2.5
ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV COLOR red
RUN echo "export COLOR=red" > /etc/hostname.color

## Prepare packages
RUN apt-get update -q
RUN apt-get install -y --no-install-recommends postgresql

##  postgresql daemon.
RUN mkdir -p /etc/service/postgresql/

## Setup supervisor services.
ADD supervisor/oar-server.conf /etc/supervisor/conf.d/oar-server.conf
ADD supervisor/postgresql.conf /etc/supervisor/conf.d/postgresql.conf

ADD sbin /usr/local/sbin
RUN chmod +x /usr/local/sbin/*

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Configure database
# configure PostgreSQL to listen for remote connections
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/9.1/main/postgresql.conf
# configure PostgreSQL to accept remote connections (from any host):
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/9.1/main/pg_hba.conf
# set insecure postgres password
RUN service postgresql start && \
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

EXPOSE 22

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs", "--enable-insecure-key"]
