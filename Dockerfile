FROM ubuntu:focal

LABEL maintainer="ebtcorg"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV MYSQL_HOSTNAME="localhost" \
    MYSQL_DATABASE="piler" \
    MYSQL_PILER_PASSWORD="piler123" \
    MYSQL_ROOT_PASSWORD="abcde123" \
    PACKAGE="${PACKAGE:-piler-1.3.8.tar.gz}"

# must be set in two steps, as in in one the env is still emty
ENV PUID_NAME="${PUID_NAME:-piler}"
ENV PILER_USER="${PUID_NAME}"

ENV BUILD_DIR="${BUILD_DIR:-/BUILD}"
RUN mkdir -p ${BUILD_DIR}

ENV HOME="/var/piler" \
PUID_NAME=${PUID_NAME:-abc} \
PUID=${PUID:-9001} \
PGID=${PGID:-9001}

RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
 nvi wget curl rsyslog openssl sysstat php7.4-cli php7.4-cgi php7.4-mysql php7.4-fpm php7.4-zip php7.4-ldap \
 php7.4-gd php7.4-curl php7.4-xml catdoc unrtf poppler-utils nginx tnef sudo libodbc1 libpq5 libzip5 \
 libtre5 libwrap0 cron libmariadb3 python3 python3-mysqldb php-memcached memcached mariadb-client gpgv1 gpgv2 \
 sphinxsearch libmariadb-dev build-essential \
 libcurl4-openssl-dev php7.4-dev libwrap0-dev libtre-dev libzip-dev libc6 libc6-dev

# need on ubuntu / debian etc
RUN \
 printf "www-data ALL=(root:root) NOPASSWD: /etc/init.d/rc.piler reload\n" > /etc/sudoers.d/81-www-data-sudo-rc-piler-reload && \
 printf "Defaults\\072\\045www-data \\041requiretty\\n" >> /etc/sudoers.d/81-www-data-sudo-rc-piler-reload && \
 chmod 0440 /etc/sudoers.d/81-www-data-sudo-rc-piler-reload

# need on Centos / Redhat etc
RUN \
 printf "apache ALL=(root:root) NOPASSWD: /etc/init.d/rc.piler reload\n" > /etc/sudoers.d/82-apache-sudo-rc-piler-reload && \
 printf "Defaults\\072\\045apache \\041requiretty\\n" >> /etc/sudoers.d/82-apache-sudo-rc-piler-reload && \
 chmod 0440 /etc/sudoers.d/82-apache-sudo-rc-piler-reload

RUN \
    sed -i 's/^/###/' /etc/init.d/sphinxsearch && \
    echo "### piler install, comment full file to stop the OS reindex" >> /etc/init.d/sphinxsearch && \
    sed -i 's/mail.[iwe].*//' /etc/rsyslog.conf && \
    sed -i '/session    required     pam_loginuid.so/c\#session    required     pam_loginuid.so' /etc/pam.d/cron && \
    mkdir /etc/piler && \
    printf "[mysql]\nuser = piler\npassword = ${MYSQL_PILER_PASSWORD}\n" > /etc/piler/.my.cnf && \
    printf "[mysql]\nuser = root\npassword = ${MYSQL_ROOT_PASSWORD}\n" > /root/.my.cnf && \
    echo "alias mysql='mysql --defaults-file=/etc/piler/.my.cnf'" > /root/.bashrc && \
    echo "alias t='tail -f /var/log/syslog'" >> /root/.bashrc

ADD "https://bitbucket.org/jsuto/piler/downloads/${PACKAGE}" "/${PACKAGE}"

RUN echo "**** install piler package via source tgz ****"  && \
    tar --directory=${BUILD_DIR} --restrict --strip-components=1 -zxvf ${PACKAGE} && \
    rm -f ${PACKAGE}

RUN groupadd --gid $PGID piler
RUN useradd --uid $PUID -g piler -d /var/piler -s /bin/bash piler
RUN usermod -L piler
RUN mkdir /var/piler && chmod 755 /var/piler

RUN echo "**** patch piler source ****"
COPY 101-piler-1-3-7-sphinxsearch-310-220-compatily-php-if-fix.patch ${BUILD_DIR}
RUN cd ${BUILD_DIR} && patch -p1 < ${BUILD_DIR}/101-piler-1-3-7-sphinxsearch-310-220-compatily-php-if-fix.patch

RUN echo "**** build piler package from source ****"  && \
    cd ${BUILD_DIR} && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-database=mariadb && \
    make clean all

RUN echo "**** continue with the setup ****" && \
    touch /var/log/mail.log && \
    rm -f /etc/nginx/sites-enabled/default && \
    echo "**** cleanup ****" && \
    apt-get purge --auto-remove -y && \
    apt-get clean

COPY start.sh /start.sh
COPY piler_1.3.8-postinst /piler-postinst
COPY piler_1.3.8-etc_piler-nginx.conf.dist-mod-php7.4 /piler-nginx.conf.dist

EXPOSE 25 80

VOLUME /etc/piler
VOLUME /var/piler

CMD ["/bin/bash", "/start.sh"]
