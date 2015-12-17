FROM oardocker/jessie-frontend:latest
MAINTAINER Salem Harrache "salem.harrache@inria.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN chown -R root:root /root
RUN pip install -U wheel setuptools sqlalchemy sqlalchemy-utils alembic Click SimPy zerorpc
RUN git clone https://github.com/oar-team/oar-kao.git /tmp/oar-kao
RUN pip install -U /tmp/oar-kao
RUN git clone https://github.com/oar-team/oar-coorm.git /tmp/oar-coorm
RUN pip install -U /tmp/oar-coorm
RUN rm -rf /tmp/oar-coorm /tmp/oar-kao /root/.cache
