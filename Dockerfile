FROM egofelix/baseimage:debian

MAINTAINER EgoFelix <docker@egofelix.de>

RUN /root/package.sh apt-utils
RUN /root/package.sh curl nagios4 nagios-nrpe-plugin apache2 ca-certificates dnsutils monitoring-plugins-btrfs monitoring-plugins-btrfs nagios-plugins-contrib
RUN echo "" > /etc/nagios4/objects/localhost.cfg

# Additional Plugin check_nwc_health
RUN /root/package.sh wget libsoap-lite-perl libxml-libxml-perl libjson-perl build-essential && cd /root && \
  wget https://labs.consol.de/assets/downloads/nagios/check_nwc_health-7.12.1.2.tar.gz && \
  tar xvf check_nwc_health-7.12.1.2.tar.gz && \
  rm -f check_nwc_health-7.12.1.2.tar.gz && \
  cd /root/check_nwc_health-7.12.1.2 && \
  ./configure && make && mv plugins-scripts/check_nwc_health /usr/lib/nagios/plugins/ && \
  rm -rf /root/check_nwc_health-7.12.1.2

# Additional Plugin check_ssl_cert
RUN /root/package.sh file && cd /root && \
  wget https://github.com/matteocorti/check_ssl_cert/releases/download/v1.122.0/check_ssl_cert-1.122.0.tar.gz && \
  tar xvf check_ssl_cert-1.122.0.tar.gz && \
  rm -f check_ssl_cert-1.122.0.tar.gz && \
  cd /root/check_ssl_cert-1.122.0 && \
  mv check_ssl_cert /usr/lib/nagios/plugins/ && \
  rm -rf /root/check_ssl_cert-1.122.0


# Install nagios4php
RUN /root/package.sh rrdtool librrds-perl php7.3-gd php7.3-xml
RUN cd /root && wget https://deac-ams.dl.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-0.6.26.tar.gz && tar -xvzf pnp4nagios-0.6.26.tar.gz
RUN cd /root/pnp4nagios-0.6.26 && ./configure
RUN cd /root/pnp4nagios-0.6.26 && make all
RUN cd /root/pnp4nagios-0.6.26 && make install
RUN cd /root/pnp4nagios-0.6.26 && make install-webconf
RUN cd /root/pnp4nagios-0.6.26 && make install-config
RUN cd /root/pnp4nagios-0.6.26 && make install-init

RUN ln -s /etc/httpd/conf.d/pnp4nagios.conf /etc/apache2/conf-enabled/pnp4nagios.conf
COPY conf.conf /etc/apache2/conf-enabled/pnp4nagios.conf

RUN a2enmod rewrite
RUN rm -f /usr/local/pnp4nagios/share/install.php

# Fix sizeof bug
RUN sed -i 's:if(sizeof(\$pages:if(is_array(\$pages) \&\& sizeof(\$pages:' /usr/local/pnp4nagios/share/application/models/data.php

# Cleanup
RUN /root/cleanup.sh
RUN rm -f /var/run/apache2/apache2.pid
RUN sed -i '/^PidFile/s//#&/' /etc/apache2/apache2.conf
COPY nagios4-cgi.conf /etc/apache2/conf-enabled/nagios4-cgi.conf
COPY nagios4.ini /etc/supervisor.d/nagios4.ini
COPY httpd.ini /etc/supervisor.d/httpd.ini

VOLUME /etc/nagios4/conf.d
