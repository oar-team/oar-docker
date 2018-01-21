FROM oardocker/stretch-frontend:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

USER root

#RUN systemctl unmask systemd-tmpfiles-setup.service
#RUN systemctl enable systemd-tmpfiles-setup.service

RUN chown -R root:root /root
RUN chmod a+rw /etc/oar/oar.conf
RUN touch /var/log/oar.log
RUN chmod a+rw /var/log/oar.log
    
RUN pip install https://github.com/russianidiot/public.py/archive/v0.0.41.tar.gz 
RUN pip install wheel setuptools sqlalchemy sqlalchemy-utils alembic Click SimPy zerorpc\
    flask tabulate pyzmq redis request procset pybatsim simplejson psutil pexpect  pytest\
    pytest-flask

RUN pip install https://github.com/oar-team/oar3/archive/master.zip

#RUN apt-get update
#RUN apt-get install nodejs/unstable node-gyp/unstable nodejs-dev/unstable gyp/unstable npm/unstable
#RUN apt-get install nodejs-legacy
#RUN npm install -g npm
#RUN rm /usr/bin/npm
#RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js  /usr/bin/npm
#RUN npm install -g ts-node
#RUN npm install -g gulp-cli

ADD configure_oar3.sh /tmp/configure_oar3.sh
RUN /bin/bash /tmp/configure_oar3.sh
    
RUN rm -rf /tmp/* /root/.cache
