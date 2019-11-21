FROM egofelix/baseimage:debian

MAINTAINER EgoFelix <docker@egofelix.de>

RUN /root/package.sh curl nagios4 nagios-nrpe-plugin apache2 ca-certificates dnsutils
RUN echo "" > /etc/nagios4/objects/localhost.cfg
  
# Additional Plugin check_nwc_health
RUN /root/package.sh wget libsoap-lite-perl libxml-libxml-perl libjson-perl build-essential && cd /root && wget https://labs.consol.de/assets/downloads/nagios/check_nwc_health-7.10.1.1.tar.gz && tar xvf check_nwc_health-7.10.1.1.tar.gz && rm -f check_nwc_health-7.10.1.1.tar.gz && cd /root/check_nwc_health-7.10.1.1 && ./configure && make && mv plugins-scripts/check_nwc_health /usr/lib/nagios/plugins/ && rm -rf /root/check_nwc_health-7.10.1.1

# Cleanup
RUN /root/cleanup.sh
RUN rm -f /var/run/apache2/apache2.pid
RUN sed -i '/^PidFile/s//#&/' /etc/apache2/apache2.conf
COPY nagios4-cgi.conf /etc/apache2/conf-enabled/nagios4-cgi.conf
COPY nagios4.ini /etc/supervisor.d/nagios4.ini
COPY httpd.ini /etc/supervisor.d/httpd.ini

VOLUME /etc/nagios4/conf.d
