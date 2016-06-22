FROM ubuntu:trusty

MAINTAINER Kurt Huwig

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2-utils \
    php5-apcu \
    php5-cli \
    php5-curl \
    php5-gd \
    php5-mcrypt \
    phpmyadmin \
    unzip \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Configure Apache
COPY files/apache-shopware.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite \
    && sed --in-place "s/^upload_max_filesize.*$/upload_max_filesize = 10M/" /etc/php5/apache2/php.ini \
    && php5enmod mcrypt

# Install Shopware
# COPY files/install_5.1.6_04ec396ac8d2fa8c1e088bc2bd2c8132ab56c270.zip /tmp/shopware.zip
ADD http://releases.s3.shopware.com.s3.amazonaws.com/install_5.1.6_04ec396ac8d2fa8c1e088bc2bd2c8132ab56c270.zip /tmp/shopware.zip

# Install ioncube
# COPY files/ioncube_loaders_lin_x86-64.tar.bz2 /tmp/ioncube_loaders_lin_x86-64.tar.bz2
ADD http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.bz2 /tmp/
RUN tar xvjfC /tmp/ioncube_loaders_lin_x86-64.tar.bz2 /tmp/ \
    && rm /tmp/ioncube_loaders_lin_x86-64.tar.bz2 \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube/ioncube_loader_lin_5.5.so /usr/local/ioncube \
    && rm -rf /tmp/ioncube
COPY files/00-ioncube.ini /etc/php5/apache2/conf.d/00-ioncube.ini
COPY files/00-ioncube.ini /etc/php5/cli/conf.d/00-ioncube.ini

# Configure phpMyAdmin
COPY files/disable-advanced-usage.php /etc/phpmyadmin/conf.d/disable-advanced-usage.php
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf

VOLUME ["/var/www/html"]

COPY files/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
