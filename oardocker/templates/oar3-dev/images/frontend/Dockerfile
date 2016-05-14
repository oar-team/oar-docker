FROM oardocker/jessie-frontend:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

USER root

RUN systemctl unmask systemd-tmpfiles-setup.service
RUN systemctl enable systemd-tmpfiles-setup.service

RUN chown -R root:root /root
RUN chmod a+rw /etc/oar/oar.conf
RUN touch /var/log/oar.log
RUN chmod a+rw /var/log/oar.log

RUN pip install -U wheel setuptools sqlalchemy sqlalchemy-utils alembic Click SimPy zerorpc
RUN git clone https://github.com/oar-team/oar3.git /tmp/python-packages/oar3
RUN pip install -U /tmp/python-packages/oar3[dev]

RUN apt-get update
RUN apt-get install nodejs/unstable node-gyp/unstable nodejs-dev/unstable gyp/unstable npm/unstable
RUN apt-get install nodejs-legacy
RUN npm install -g npm
RUN rm /usr/bin/npm
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js  /usr/bin/npm
RUN npm install -g ts-node
RUN npm install -g gulp-cli

RUN rm -rf /tmp/* /root/.cache
