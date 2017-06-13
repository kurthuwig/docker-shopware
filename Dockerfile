FROM ubuntu:xenial

MAINTAINER Kurt Huwig

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2 \
    apache2-utils \
    php-apcu \
    php-cli \
    php-curl \
    php-gd \
    php-mcrypt \
    php-zip \
    phpmyadmin \
    unzip \
    bzip2 \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Configure Apache
COPY files/apache-shopware.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite \
    && sed --in-place "s/^upload_max_filesize.*$/upload_max_filesize = 10M/" /etc/php/7.0/apache2/php.ini \
    && sed --in-place "s/^memory_limit.*$/memory_limit = 256M/" /etc/php/7.0/apache2/php.ini \
    && phpenmod mcrypt

# Install Shopware
# COPY files/install_5.1.6_04ec396ac8d2fa8c1e088bc2bd2c8132ab56c270.zip /tmp/shopware.zip
#ADD  http://releases.s3.shopware.com.s3.amazonaws.com/install_5.2.4_b1a52d04c9c8cd60205c181eb7d51aa5a516bff0.zip /tmp/shopware.zip
ADD http://releases.s3.shopware.com.s3.amazonaws.com/install_5.3.0_RC1_6f9db3a81a1b8bf2cd6a442e952f881c443091ff.zip?_ga=2.16608628.357092293.1497192711-1849617745.1493720407 /tmp/shopware.zip

# Install ioncube
# COPY files/ioncube_loaders_lin_x86-64.tar.bz2 /tmp/ioncube_loaders_lin_x86-64.tar.bz2
ADD https://www.ioncube.com/php7-linux-x86-64-beta8.tgz /tmp/
RUN tar xvzfC /tmp/php7-linux-x86-64-beta8.tgz /tmp/ \
    && rm /tmp/php7-linux-x86-64-beta8.tgz \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube_loader_lin_x86-64_7.0b8.so /usr/local/ioncube \
    && rm -rf /tmp/ioncube
COPY files/00-ioncube.ini /etc/php/7.0/apache2/conf.d/00-ioncube.ini
COPY files/00-ioncube.ini /etc/php/7.0/cli/conf.d/00-ioncube.ini

# Configure phpMyAdmin
COPY files/disable-advanced-usage.php /etc/phpmyadmin/conf.d/disable-advanced-usage.php
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf

VOLUME ["/var/www/html"]

COPY files/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
