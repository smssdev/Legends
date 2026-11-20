FROM php:8.5-apache
# مشغّل PostgreSQL، مترجماً داخل PHP
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev \
 && docker-php-ext-install pdo_pgsql \
 && rm -rf /var/lib/apt/lists/*
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# كل عنوان يذهب إلى index.php
RUN echo "FallbackResource /index.php" > /etc/apache2/conf-enabled/fallback.conf \
 && sed -i 's#/var/www/html#/var/www/html/public#' /etc/apache2/sites-available/000-default.conf
COPY --chown=www-data:www-data . /var/www/html
# يسأل Docker التطبيق نفسه هل هو بخير
HEALTHCHECK --interval=5s --timeout=2s CMD curl -fs http://localhost/health || exit 1
