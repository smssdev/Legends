FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY . .
RUN composer dump-autoload --optimize --no-dev

FROM php:8.5-apache
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev \
 && docker-php-ext-install pdo_pgsql pcntl \
 && rm -rf /var/lib/apt/lists/*
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN echo "FallbackResource /index.php" > /etc/apache2/conf-enabled/laravel.conf \
 && echo 'SetEnvIf Authorization "(.+)" HTTP_AUTHORIZATION=$1' >> /etc/apache2/conf-enabled/laravel.conf \
 && sed -i 's#/var/www/html#/var/www/html/public#' /etc/apache2/sites-available/000-default.conf
WORKDIR /var/www/html
COPY --from=vendor --chown=www-data:www-data /app ./
HEALTHCHECK --interval=5s --timeout=2s CMD curl -fs http://localhost/up || exit 1
