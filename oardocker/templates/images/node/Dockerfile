FROM oardocker/base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"
ENV COLOR yellow
RUN echo "export COLOR=yellow" > /etc/hostname.color

ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*

ADD supervisor/oar-node.conf /etc/supervisor/conf.d/oar-node.conf

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

## Cleanup
RUN rm -rf /tmp/* /var/tmp/* /etc/ssh/ssh_host_*

CMD ["/usr/local/sbin/my_init", "/usr/local/sbin/taillogs", "--enable-insecure-key"]
