FROM oarcluster/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

RUN echo "export COLOR=yellow" > /etc/hostname.color

ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*

ADD supervisor/oar-node.conf /etc/supervisor/conf.d/oar-node.conf

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs", "--enable-insecure-key"]
