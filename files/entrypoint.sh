#!/bin/bash

if [ ! -e /var/www/html/shopware.php ]; then
    echo -n "Shopware not found, installing..."
    rm -f /var/www/html/index.html \
    && unzip -d /var/www/html /tmp/shopware.zip || exit 1
    echo "done"
fi

echo -n "Setting permissions..."
for i in logs/ \
              config.php \
              var/log/ \
              var/cache/ \
              web/cache/ \
              files/documents/ \
              files/downloads/ \
              recovery/ \
              engine/Shopware/Plugins/Community/ \
              engine/Shopware/Plugins/Community/Frontend \
              engine/Shopware/Plugins/Community/Core \
              engine/Shopware/Plugins/Community/Backend \
              engine/Shopware/Plugins/Default/ \
              engine/Shopware/Plugins/Default/Frontend \
              engine/Shopware/Plugins/Default/Core \
              engine/Shopware/Plugins/Default/Backend \
              themes/Frontend \
              media/archive/ \
              media/image/ \
              media/image/thumbnail/ \
              media/music/ \
              media/pdf/ \
              media/unknown/ \
              media/video/ \
              media/temp/ \
              recovery/install/data; do
      chown www-data /var/www/html/$i
done
echo "done"

if [ -f /etc/apache2/phpmyadmin.htpasswd ]
then
  HTPASSWD_OPTS=-Bbi
else
  HTPASSWD_OPTS=-cBbi
fi

if [ -n "$PHPMYADMIN_PW" ]; then
    htpasswd -Bbc /etc/apache2/phpmyadmin.htpasswd phpmyadmin "${PHPMYADMIN_PW}"
fi

cat > /var/www/html/config.php << EOF
<?php
return array(
    'db' => array(
        'username' => '${DB_USER:-shopware}',
        'password' => '${DB_PASSWORD:-shopware}',
        'dbname' => '${DB_DATABASE:-shopware}',
        'host' => '${DB_HOST:-${DB_PORT_3306_TCP_ADDR}}',
        'port' => '${DB_PORT:-${DB_PORT_3306_TCP_PORT:-3306}}'
    )
);
EOF

cat > /etc/phpmyadmin/config-db.php << EOF
<?php
\$dbuser='${DB_USER:-shopware}';
\$dbpass='${DB_PASSWORD:-shopware}';
\$basepath='';
\$dbname='${DB_DATABASE:-shopware}';
\$dbserver='${DB_HOST:-${DB_PORT_3306_TCP_ADDR}}';
\$dbport='${DB_PORT:-${DB_PORT_3306_TCP_PORT:-3306}}';
\$dbtype='mysql';
EOF

source /etc/apache2/envvars
exec apache2 -D FOREGROUND
