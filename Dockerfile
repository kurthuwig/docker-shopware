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
# COPY files/install_5.3.2_5ab7c48a261445eaeb25273cb34c1a6ae3102741.zip /tmp/shopware.zip
ADD http://releases.s3.shopware.com.s3.amazonaws.com/install_5.3.2_5ab7c48a261445eaeb25273cb34c1a6ae3102741.zip /tmp/shopware.zip

# Install ioncube
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/
RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ \
    && rm /tmp/ioncube_loaders_lin_x86-64.tar.gz \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube/ioncube_loader_lin_7.0.so /usr/local/ioncube \
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
