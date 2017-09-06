FROM oardocker/stretch-base:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

ENV COLOR magenta
RUN echo "export COLOR=magenta" > /etc/hostname.color

COPY config/rsyslog.conf /etc/

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*

CMD ["rsyslogd", "-n"]
