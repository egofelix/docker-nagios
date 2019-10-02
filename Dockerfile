FROM egofelix/baseimage:debian

MAINTAINER EgoFelix <docker@egofelix.de>

#RUN /root/package.sh software-properties-common
#RUN apt-add-repository non-free
#RUN apt-add-repository contrib
#RUN apt-get update

RUN /root/package.sh curl nagios4 nagios-nrpe-plugin apache2
RUN mkdir -p /etc/supervisor.d
RUN /root/cleanup.sh

COPY nagios4-cgi.conf /etc/apache2/conf-enabled/nagios4-cgi.conf
COPY nagios4.ini /etc/supervisor.d/nagios4.ini
COPY httpd.ini /etc/supervisor.d/httpd.ini

VOLUME /etc/nagios4/conf.d