FROM oardocker/jessie-server:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

RUN chown -R root:root /root
RUN chmod a+rw /etc/oar/oar.conf
RUN touch /var/log/oar.log
RUN chmod a+rw /var/log/oar.log

RUN pip install -U wheel setuptools sqlalchemy sqlalchemy-utils alembic Click SimPy zerorpc
RUN mkdir /tmp/python-packages/
RUN git clone https://github.com/oar-team/oar-lib.git /tmp/python-packages/oar-lib
RUN git clone https://github.com/oar-team/oar-kao.git /tmp/python-packages/oar-kao
RUN pip install -U /tmp/python-packages/oar-lib
RUN pip install -U /tmp/python-packages/oar-kao[coorm]

RUN rm -rf /tmp/* /root/.cache
