FROM debian:wheezy
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV HOME /root
RUN mkdir /build
ADD . /build

RUN /build/prepare.sh
RUN /build/utilities.sh
RUN /build/system_services.sh
RUN /build/cleanup.sh

CMD ["/sbin/my_init"]
