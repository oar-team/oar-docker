FROM oardocker/bullseye-base:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV COLOR magenta
RUN echo "export COLOR=magenta" > /etc/hostname.color

COPY config/rsyslog.conf /etc/

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*

CMD ["rsyslogd", "-n"]
