# The PHP that runs every PHP example of Book 3 (Laravel edition): PHP 8.5 with the extensions the
# book uses, and Composer. Redis is reached with Predis, a Composer package, so no extension is needed. Built by bin/php the first time it is needed.
FROM php:8.5-cli
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev libicu-dev libzip-dev unzip git \
 && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath pcntl \
 && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_HOME=/tmp/composer
