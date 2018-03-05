FROM oardocker/stretch-frontend:latest
MAINTAINER Olivier Richard "olivier.richard@imag.fr"

USER root

#RUN systemctl unmask systemd-tmpfiles-setup.service
#RUN systemctl enable systemd-tmpfiles-setup.service

RUN chown -R root:root /root
RUN chmod a+rw /etc/oar/oar.conf
RUN touch /var/log/oar.log
RUN chmod a+rw /var/log/oar.log
    
#RUN pip install https://github.com/russianidiot/public.py/archive/v0.0.41.tar.gz 
RUN pip install wheel setuptools sqlalchemy sqlalchemy-utils alembic Click SimPy zerorpc\
    flask tabulate pyzmq redis request procset pybatsim simplejson psutil pexpect  pytest\
    pytest-flask

RUN pip install https://github.com/oar-team/oar3/archive/master.zip

ADD configure_oar3.sh /tmp/configure_oar3.sh
RUN /bin/bash /tmp/configure_oar3.sh

ADD oarswitch-cli /usr/sbin/oarswitch-cli

RUN echo "Install NIX"
USER docker        
RUN export USER=docker && curl https://nixos.org/nix/install | /bin/sh

RUN echo "if [ -f /home/docker/.nix-profile/etc/profile.d/nix.sh ]; then\n\
    source /home/docker/.nix-profile/etc/profile.d/nix.sh\n\
fi\n" >> /home/docker/.bashrc
 
RUN /home/docker/.nix-profile/bin/nix-env -i nodejs

USER root                
RUN rm -rf /tmp/* /root/.cache

EXPOSE 4200