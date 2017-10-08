FROM oardocker/jessie-frontend:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

RUN chown -R root:root /root
RUN chmod a+rw /etc/oar/oar.conf
RUN touch /var/log/oar.log
RUN chmod a+rw /var/log/oar.log

RUN pip install -U wheel setuptools sqlalchemy sqlalchemy-utils alembic Click SimPy zerorpc
RUN git clone https://github.com/oar-team/oar3.git /tmp/python-packages/oar3
RUN pip install -U /tmp/python-packages/oar3[coorm]

RUN rm -rf /tmp/* /root/.cache
