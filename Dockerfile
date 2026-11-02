# One image with the whole game: the Laravel API, the built Vue app and the imported club data. Run on our server
# beside its PostgreSQL (deploy/vps/compose.yml), or anywhere to try it: docker build -t legends . && docker run -p
# 8000:8000 legends (without DATABASE_URL the game lives in the image's SQLite file and is wiped on restart).

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
# The RenderFrame golden vectors, checked before the build [Sprint 21 E8.4].
COPY docs/api/frame-golden.json ./docs/api/frame-golden.json
# [Sprint 39 B3] The site's address (PUBLIC_URL on the server, deploy/vps/compose.yml) goes into the canonical links, the
# sitemap and the cards; nesr.site when built without it.
ARG PUBLIC_URL=https://nesr.site
ENV VITE_SITE_URL=$PUBLIC_URL
RUN cd web && npm run build

FROM composer:2 AS vendor
WORKDIR /app/backend
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress --no-scripts --no-autoloader

FROM php:8.4-cli-alpine
WORKDIR /app/backend
# GD makes the accounts' pictures small squares (App\Support\Avatar).
# pdo_pgsql: the game's database (PostgreSQL) [X43, X48]. pcntl: Reverb, the live updates on our server [X48].
RUN apk add --no-cache libpng libjpeg-turbo libwebp freetype libpq \
 && apk add --no-cache --virtual .gd-build libpng-dev libjpeg-turbo-dev libwebp-dev freetype-dev postgresql-dev \
 && docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype \
 && docker-php-ext-install -j"$(nproc)" gd pdo_pgsql pcntl opcache \
 && apk del .gd-build
# [X45] OPcache, for the web server too (it runs as php -S, a CLI process): Laravel is compiled once per start instead
# of on every request. The code never changes inside the container, so files are not checked again.
RUN { echo 'opcache.enable=1'; echo 'opcache.enable_cli=1'; echo 'opcache.memory_consumption=96'; \
      echo 'opcache.interned_strings_buffer=16'; echo 'opcache.max_accelerated_files=20000'; \
      echo 'opcache.validate_timestamps=0'; echo 'realpath_cache_size=4096K'; echo 'realpath_cache_ttl=600'; } \
      > /usr/local/etc/php/conf.d/zz-legends-speed.ini
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY backend ./
COPY data /app/data
COPY --from=vendor /app/backend/vendor ./vendor
COPY --from=web /app/web/dist ./public-web
RUN composer dump-autoload --optimize --no-dev \
 && cp -r public-web/. public/ && rm -rf public-web \
 && find public -type f \( -name '*.js' -o -name '*.css' -o -name '*.json' -o -name '*.svg' -o -name '*.html' -o -name '*.wasm' -o -name '*.data' \) -size +1k -exec gzip -k -9 {} \; \
 && apk add --no-cache --virtual .brotli brotli \
 && find public -type f \( -name '*.js' -o -name '*.css' -o -name '*.json' -o -name '*.svg' -o -name '*.html' -o -name '*.wasm' -o -name '*.data' \) -size +1k -exec brotli -k -q 11 {} \; \
 && apk del .brotli \
 && cp .env.example .env \
 && sed -i 's/^APP_ENV=.*/APP_ENV=demo/; s/^APP_DEBUG=.*/APP_DEBUG=false/; s/^BROADCAST_CONNECTION=.*/BROADCAST_CONNECTION=log/' .env \
 && echo "SIMULATOR_ENABLED=true" >> .env \
 && php artisan key:generate --force \
 && php artisan migrate --force \
 && php artisan data:import \
 && chown -R www-data:www-data storage database bootstrap/cache

# The start script: the public address, sign-in, email and Google from the run-time variables, the configuration
# cached then (not here, before they are known), and the queue, scheduler, live matches and Reverb.
COPY deploy/docker/start.sh /app/start.sh
COPY deploy/docker/router.php /app/backend/router.php
ENV PORT=8000 PHP_CLI_SERVER_WORKERS=4
EXPOSE 8000
USER www-data
CMD ["sh", "/app/start.sh"]
