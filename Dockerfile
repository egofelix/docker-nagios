
FROM alpine AS builder

ENV NAGIOS_HOME=/opt/nagios \
    NAGIOS_USER=nagios \
    NAGIOS_GROUP=nagios \
    NAGIOS_CMDUSER=nagios \
    NAGIOS_CMDGROUP=nagios \
    NAGIOS_BRANCH=nagios-4.4.6 \
    NAGIOS_PLUGINS_BRANCH=release-2.3.3 \
    NAGIOS_PLUGIN_NWC_HEALTH_VERSION=7.12.1.3 \
    PNP4NAGIOS_VERSION=0.6.26 \
    NRPE_BRANCH=nrpe-4.0.3

# Prepare environment
RUN addgroup -S ${NAGIOS_GROUP} && \
    adduser  -S ${NAGIOS_USER} -G ${NAGIOS_CMDGROUP} && \
    apk add --no-cache build-base automake libtool autoconf py-docutils gnutls  \
                        gnutls-dev g++ make alpine-sdk build-base gcc autoconf \
                        gettext-dev linux-headers openssl-dev apache2 apache2-utils \
                        wget procps unzip rrdtool

# Download Nagios core, plugins and nrpe sources                        
RUN    cd /tmp && \
       echo -n "Downloading Nagios ${NAGIOS_BRANCH} source code: " && \
       wget -q -O nagios-core.tar.gz "https://github.com/NagiosEnterprises/nagioscore/archive/${NAGIOS_BRANCH}.tar.gz" && \
       echo -n -e "OK\nDownloading Nagios plugins ${NAGIOS_PLUGINS_BRANCH} source code: " && \
       wget -q -O nagios-plugins.tar.gz "https://github.com/nagios-plugins/nagios-plugins/archive/${NAGIOS_PLUGINS_BRANCH}.tar.gz" && \
       echo -n -e "OK\nDownloading NRPE ${NRPE_BRANCH} source code: " && \
       wget -q -O nrpe.tar.gz "https://github.com/NagiosEnterprises/nrpe/archive/${NRPE_BRANCH}.tar.gz" && \
       echo -n -e "OK\nDownloading check_nwc_health ${NAGIOS_PLUGIN_NWC_HEALTH_VERSION} source code: " && \
       wget -q -O check_new_health.tar.gz "https://labs.consol.de/assets/downloads/nagios/check_nwc_health-${NAGIOS_PLUGIN_NWC_HEALTH_VERSION}.tar.gz" && \
       echo -n -e "OK\nDownloading pnp4nagios ${PNP4NAGIOS_VERSION} source code: " && \
       wget -q -O pnp4nagios.tar.gz "https://deac-ams.dl.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-${PNP4NAGIOS_VERSION}.tar.gz" && \
       echo "OK"

# Unpack sources
RUN cd /tmp && \
       tar zxf nagios-core.tar.gz && \
       tar zxf nagios-plugins.tar.gz && \
       tar zxf nrpe.tar.gz && \
       tar zxf check_new_health.tar.gz && \
       tar zxf pnp4nagios.tar.gz

# Compile Nagios Core
RUN    cd  "/tmp/nagioscore-${NAGIOS_BRANCH}" && \
       echo -e "\n ===========================\n  Configure Nagios Core\n ===========================\n" && \
       ./configure \
            --prefix=${NAGIOS_HOME}                  \
            --exec-prefix=${NAGIOS_HOME}             \
            --enable-event-broker                    \
            --with-command-user=${NAGIOS_CMDUSER}    \
            --with-command-group=${NAGIOS_CMDGROUP}  \
            --with-nagios-user=${NAGIOS_USER}        \
            --with-nagios-group=${NAGIOS_GROUP}      && \
       echo -n "Replacing \"<sys\/poll.h>\" with \"<poll.h>\": " && \
       sed -i 's/<sys\/poll.h>/<poll.h>/g' ./include/config.h && \
       echo -e "\n\n ===========================\n Compile Nagios Core\n ===========================\n" && \
       make all && \
       echo -e "\n\n ===========================\n  Install Nagios Core\n ===========================\n" && \
       make install && \
       make install-commandmode && \
       make install-config && \
       make install-webconf && \
       echo -n "Nagios installed size: " && \
       du -h -s ${NAGIOS_HOME}

# Compile Nagios Plugins
RUN    echo -e "\n\n ===========================\n  Configure Nagios Plugins\n ===========================\n" && \
       cd  /tmp/nagios-plugins-${NAGIOS_PLUGINS_BRANCH} && \
       ./autogen.sh && \
       ./configure  --with-nagios-user=${NAGIOS_USER} \
                    --with-nagios-group=${NAGIOS_USER} \
                    --with-openssl \
                    --prefix=${NAGIOS_HOME} \
                    --with-ping-command="/bin/ping -n -w %d -c %d %s" \
                    --with-ipv6 \
                    --with-ping6-command="/bin/ping6 -n -w %d -c %d %s" && \
       echo "Nagios plugins configured: OK" && \
       echo -n "Replacing \"<sys\/poll.h>\" with \"<poll.h>\": " && \
       egrep -rl "\<sys\/poll.h\>" . | xargs sed -i 's/<sys\/poll.h>/<poll.h>/g' && \
       egrep -rl "\"sys\/poll.h\"" . | xargs sed -i 's/"sys\/poll.h"/"poll.h"/g' && \
       echo "OK" && \
       echo -e "\n\n ===========================\n Compile Nagios Plugins\n ===========================\n" && \
       make && \
       echo "Nagios plugins compile successfully: OK" && \
       echo -e "\n\n ===========================\nInstall Nagios Plugins\n ===========================\n" && \
       make install && \
       echo "Nagios plugins installed successfully: OK"

# Compile NRPE
RUN    echo -e "\n\n =====================\n  Configure NRPE\n =====================\n" && \
       cd  /tmp/nrpe-${NRPE_BRANCH} && \
       ./configure --enable-command-args \
                    --with-nagios-user=${NAGIOS_USER} \
                    --with-nagios-group=${NAGIOS_USER} \
                    --with-ssl=/usr/bin/openssl \
                    --with-ssl-lib=/usr/lib && \
       echo "NRPE client configured: OK" && \
       echo -e "\n\n ===========================\n  Compile NRPE\n ===========================\n" && \
       # make all && \
       make check_nrpe                                                          && \
       echo "NRPE compiled successfully: OK" && \
       echo -e "\n\n ===========================\n  Install NRPE\n ===========================\n" && \
       # make install && \
       cp src/check_nrpe ${NAGIOS_HOME}/libexec/                                && \
       echo "NRPE installed successfully: OK" && \
       echo -n "Final Nagios installed size: " && \
       du -h -s ${NAGIOS_HOME} 

# Compile check_nwc_health
RUN    echo -e "\n\n =====================\n  Configure check_nwc_health\n =====================\n" && \
       cd  /tmp/check_nwc_health-${NAGIOS_PLUGIN_NWC_HEALTH_VERSION} && \
       ./configure && \
       echo "check_nwc_health configured: OK" && \
       echo -e "\n\n ===========================\n  Compile check_nwc_health\n ===========================\n" && \
       make && \
       echo "check_nwc_health compiled successfully: OK" && \
       echo -e "\n\n ===========================\n  Install check_nwc_health\n ===========================\n" && \
       cp plugins-scripts/check_nwc_health /opt/nagios/libexec/check_nwc_health

# Compile pnp4nagios
RUN    echo -e "\n\n =====================\n  Configure pnp4nagios\n =====================\n" && \
       cd  /tmp/pnp4nagios-${PNP4NAGIOS_VERSION} && \
       ./configure && \
       echo "pnp4nagios configured: OK" && \
       echo -e "\n\n ===========================\n  Compile pnp4nagios\n ===========================\n" && \
       make all && \
       make install && \
       make install-webconf && \
       make install-config && \
       make install-init && \
       rm -f /usr/local/pnp4nagios/share/install.php && \
# Fix sizeof bug
       sed -i 's:if(sizeof(\$pages:if(is_array(\$pages) \&\& sizeof(\$pages:' /usr/local/pnp4nagios/share/application/models/data.php && \
# Fix broken constructors
       sed -i 's:function Services_JSON_Error(:function _construct(:' /usr/local/pnp4nagios/share/application/lib/json.php && \
       sed -i 's:function Services_JSON(:function _construct(:' /usr/local/pnp4nagios/share/application/lib/json.php && \
       echo "pnp4nagios compiled successfully: OK"

# Main Image
FROM alpine

ENV NAGIOS_HOME=/opt/nagios \
    NAGIOS_USER=nagios \
    NAGIOS_GROUP=nagios \
    NAGIOS_CMDUSER=nagios \
    NAGIOS_CMDGROUP=nagios

RUN mkdir -p ${NAGIOS_HOME}
WORKDIR ${NAGIOS_HOME}

# Copy binarys
COPY --from=builder ${NAGIOS_HOME} ${NAGIOS_HOME}
COPY --from=builder /usr/local/pnp4nagios/ /usr/local/pnp4nagios/

# Install dependencies
RUN apk add --no-cache \
      curl \
      bash \
      nginx \
      php7-fpm \
      php7-iconv \
      php7-session \
      php7-simplexml \
      php7-gd \
      ttf-dejavu \
      rrdtool \
      bind-tools \
      fcgiwrap \
      supervisor \
      perl \
      iputils \
      libltdl \
      libintl && \
    addgroup -S ${NAGIOS_GROUP} && \
    adduser  -S ${NAGIOS_USER} -G ${NAGIOS_CMDGROUP} && \
    chown -R nagios:nagios ${NAGIOS_HOME} && \
    chown -R nagios:nagios /usr/local/pnp4nagios && \
    mkdir -p /run/nginx && \
    mkdir -p /run/fcgi && chown -R nagios:nagios /run/fcgi

# Add perl modules from testing required for check_nwc_health
RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache \
      perl-soap-lite@testing \
      perl-xml-libxml@testing \
      perl-html-tree@testing \
      perl-json@testing

# Copy Supervisor Units
COPY nagios4.ini /etc/supervisor.d/nagios4.ini
COPY nginx.ini /etc/supervisor.d/nginx.ini
COPY php-fpm.ini /etc/supervisor.d/php-fpm.ini
COPY fcgi.ini /etc/supervisor.d/fcgi.ini
COPY nginx.conf /etc/nginx/nginx.conf
COPY reload.sh /reload.sh

# Run supervisor
ENTRYPOINT /usr/bin/supervisord --nodaemon --configuration /etc/supervisord.conf
