FROM egofelix/baseimage:debian

MAINTAINER EgoFelix <docker@egofelix.de>

RUN /root/package.sh curl nagios4 nagios-nrpe-plugin apache2
RUN /root/cleanup.sh

COPY nagios4-cgi.conf /etc/apache2/conf-enabled/nagios4-cgi.conf
COPY nagios4.ini /etc/supervisor.d/nagios4.ini
COPY httpd.ini /etc/supervisor.d/httpd.ini

VOLUME /etc/nagios4/conf.d
