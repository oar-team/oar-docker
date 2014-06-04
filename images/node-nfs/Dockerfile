FROM oarcluster/nfs-client
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

# Download oar
ADD version.txt /tmp/version.txt
RUN wget -q https://github.com/oar-team/oar/archive/$(cat /tmp/version.txt).tar.gz -O /tmp/oar-$(cat /tmp/version.txt).tar.gz
RUN tar xf /tmp/oar-$(cat /tmp/version.txt).tar.gz -C /tmp/

## Install OAR node
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-build
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-install
RUN make -C /tmp/oar-$(cat /tmp/version.txt)/ PREFIX=/usr/local node-setup

ENV installDIR "/usr/local"
RUN sudo apt-get update
RUN sudo apt-get install -y autotools-dev g++ build-essential gfortran
RUN sudo apt-get autoremove
RUN n=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $NF}'`
RUN wget http://www.open-mpi.org/software/ompi/v1.6/downloads/openmpi-1.6.5.tar.gz
RUN tar xzvf openmpi-1.6.5.tar.gz
RUN cd ~/openmpi-1.6.5/
#RUN echo "Beginning the installation..."
RUN pwd
RUN ~/openmpi-1.6.5/configure --prefix="/usr/local"
RUN make -j $n
RUN make install
RUN sudo ldconfig
RUN echo
RUN echo "open mpi ...done."

ADD sbin/oar-node /sbin/oar-node
ADD supervisor /etc/supervisor/conf.d
ADD cmd.sh /sbin/cmd.sh

## Cleanup
RUN rm -rf /tmp/*

CMD ["/sbin/my_init", "/sbin/cmd.sh"]
