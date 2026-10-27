# One image with everything for the simulator demo: the Laravel API, the built
# Vue app and the imported club data. Used by Render (render.yaml) and runnable
# anywhere with: docker build -t legends . && docker run -p 8000:8000 legends
# Free hosts wipe the disk on restart: on Render, Litestream keeps the databases in Backblaze B2 and brings
# them back on start (deploy/render/start.sh), so the game and its accounts are kept.

FROM node:22-alpine AS web
WORKDIR /app
COPY docs/design ./docs/design
COPY web/package.json web/package-lock.json ./web/
RUN cd web && npm ci
COPY web ./web
# The commentator's line table, shared with the server [Sprint 35].
COPY backend/resources/commentary/voice.json ./backend/resources/commentary/voice.json
# The Arabic names of the leagues, clubs and players [X40]: the names dictionary the build writes.
COPY data/names ./data/names
COPY data/arab/arab_players.csv ./data/arab/arab_players.csv
RUN cd web && npm run build

FROM composer:2 AS vendor
WORKDIR /app/backend
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress --no-scripts --no-autoloader

FROM php:8.4-cli-alpine
WORKDIR /app/backend
# GD makes the accounts' pictures small squares (App\Support\Avatar).
# pdo_pgsql: the game's database in Supabase (PostgreSQL) [X43].
RUN apk add --no-cache libpng libjpeg-turbo libwebp freetype libpq \
 && apk add --no-cache --virtual .gd-build libpng-dev libjpeg-turbo-dev libwebp-dev freetype-dev postgresql-dev \
 && docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype \
 && docker-php-ext-install -j"$(nproc)" gd pdo_pgsql opcache \
 && apk del .gd-build
# [X45] OPcache, for the web server too (it runs as php -S, a CLI process): Laravel is compiled once per start instead
# of on every request. The code never changes inside the container, so files are not checked again.
RUN { echo 'opcache.enable=1'; echo 'opcache.enable_cli=1'; echo 'opcache.memory_consumption=96'; \
      echo 'opcache.interned_strings_buffer=16'; echo 'opcache.max_accelerated_files=20000'; \
      echo 'opcache.validate_timestamps=0'; echo 'realpath_cache_size=4096K'; echo 'realpath_cache_ttl=600'; } \
      > /usr/local/etc/php/conf.d/zz-legends-speed.ini
# Litestream (free, open source): copies every change to the databases to B2 and brings it back on start.
ARG LITESTREAM_VERSION=0.3.13
ADD https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-amd64.tar.gz /tmp/litestream.tar.gz
RUN tar -xzf /tmp/litestream.tar.gz -C /usr/local/bin litestream && rm /tmp/litestream.tar.gz
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY backend ./
COPY data /app/data
COPY --from=vendor /app/backend/vendor ./vendor
COPY --from=web /app/web/dist ./public-web
RUN composer dump-autoload --optimize --no-dev \
 && cp -r public-web/. public/ && rm -rf public-web \
 && find public -type f \( -name '*.js' -o -name '*.css' -o -name '*.json' -o -name '*.svg' -o -name '*.html' -o -name '*.wasm' -o -name '*.data' \) -size +1k -exec gzip -k -9 {} \; \
 && cp .env.example .env \
 && sed -i 's/^APP_ENV=.*/APP_ENV=demo/; s/^APP_DEBUG=.*/APP_DEBUG=false/; s/^BROADCAST_CONNECTION=.*/BROADCAST_CONNECTION=log/' .env \
 && echo "SIMULATOR_ENABLED=true" >> .env \
 && php artisan key:generate --force \
 && php artisan migrate --force \
 && php artisan data:import \
 && chown -R www-data:www-data storage database bootstrap/cache

# The start script: the public address, sign-in, Gmail and Google from the host's run-time variables, the
# configuration cached then (not here, before they are known), and the queue, scheduler and live matches.
COPY deploy/render/start.sh /app/start.sh
COPY deploy/render/maintenance.php /app/maintenance.php
COPY deploy/render/litestream.yml /app/litestream.yml
COPY deploy/render/router.php /app/backend/router.php
ENV PORT=8000 PHP_CLI_SERVER_WORKERS=4
EXPOSE 8000
USER www-data
CMD ["sh", "/app/start.sh"]
