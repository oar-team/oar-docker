FROM oardocker/debian8:1.3
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

ENV COLOR purple
RUN echo "export COLOR=purple" > /etc/hostname.color

RUN apt-get update && \
    apt-get install rsyslog --no-install-recommends -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY config/rsyslog.conf /etc/

ADD . /tmp
RUN echo "Running custom setup script..." && /bin/bash /tmp/custom_setup.sh  && rm -rf /tmp/*

VOLUME /var/run/rsyslog/dev

CMD ["rsyslogd", "-n"]
