#!/bin/bash

  # Install oar
  /bin/bash /root/install_oar.sh $*

  # Cigri pull
  cd /root
  git clone https://github.com/oar-team/cigri.git

  # Cigri install
  cd /root/cigri
  make install-cigri 
  make install-autogenerated-cert
  make setup

  # Apache configuration (api activation)
  ln -s /etc/cigri/api-apache.conf /etc/apache2/conf-available/cigri-api.conf
  a2enconf cigri-api

  # Cigri config file customization
  perl -pi -e 's/^DATABASE_HOST.*=.*/DATABASE_HOST = "server"/' /etc/cigri/cigri.conf
  perl -pi -e 's/^LOG_LEVEL.*=.*/LOG_LEVEL = "DEBUG"/' /etc/cigri/cigri.conf
  perl -pi -e 's/^LOG_FILE.*=.*/LOG_FILE = "STDERR"/' /etc/cigri/cigri.conf

  # OARAPI for CIGRI
  cp tools/oardocker/oar-restful-api-secured.conf /etc/apache2/conf-available
  a2enconf oar-restful-api-secured
  a2enmod ssl
  a2ensite default-ssl