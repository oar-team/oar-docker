FROM oardocker/jessie-colmet-base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"
ENV COLOR yellow
RUN echo "export COLOR=yellow" > /etc/hostname.color

# kvm utils
RUN apt-get update ;\
    apt-get install -y \
    psmisc iptables socat ifupdown isc-dhcp-client net-tools iproute2 \
    qemu-kvm linux-image-amd64 bridge-utils uml-utilities build-essential

RUN echo "blacklist pcspkr" >> /etc/modprobe.d/fbdev-blacklist.conf ;\
    printf '%s\n' 9p 9pnet 9pnet_virtio | tee -a /etc/initramfs-tools/modules ;\
    update-initramfs -u

## add helpers scripts:
ADD sbin/ /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*
ADD bin/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

## Add postinstall scripts
ADD install_oar.sh /root/install_oar.sh
RUN chmod +x /root/*.sh

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*
