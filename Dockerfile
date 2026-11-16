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
# [Sprint 57, fixed in Sprint 66] The minute's story words (App\Simulator\MomentStory): scripts/i18n.mjs checks each has
# its English, and scripts/story-words.mjs writes them for the app. Missing here, every image build stopped there.
COPY backend/app/Simulator/MomentStory.php ./backend/app/Simulator/MomentStory.php
# The Arabic names of the leagues, clubs and players [X40]: the names dictionary the build writes.
COPY data/names ./data/names
COPY data/arab/arab_players.csv ./data/arab/arab_players.csv
# The RenderFrame golden vectors, checked before the build [Sprint 21 E8.4].
COPY docs/api/frame-golden.json ./docs/api/frame-golden.json
# [Sprint 63, fixed in Sprint 66] The icons' one source: scripts/icons.mjs checks the site's icons come from it.
COPY brand/icons ./brand/icons
# [Sprint 39 B3] The site's address (PUBLIC_URL on the server, deploy/vps/compose.yml) goes into the canonical links, the
# sitemap and the cards; gamelegendmanager.online when built without it (X77).
ARG PUBLIC_URL=https://gamelegendmanager.online
ENV VITE_SITE_URL=$PUBLIC_URL
RUN cd web && npm run build

FROM composer:2 AS vendor
WORKDIR /app/backend
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress --no-scripts --no-autoloader

# [Sprint 52 B3] FrankenPHP (Caddy with PHP inside, free and open source) in place of PHP's development server: Caddy
# sends the built files itself (no PHP worker held by a 200 KB script or a 23 MB APK, their Brotli and gzip copies
# made below), and PHP takes every other request on as many threads as it needs instead of 4 fixed workers.
FROM dunglas/frankenphp:1-php8.4-alpine
WORKDIR /app/backend
# GD makes the accounts' pictures small squares (App\Support\Avatar). pdo_pgsql: the game's database (PostgreSQL)
# [X43, X48]. pcntl: Reverb [X48]. redis: the cache, the sessions and the queue [Sprint 52 B4]. gmp and bcmath [X106]: the
# web push library (minishlink/web-push) warns without them, and Laravel turns the warning into an error: every SendPush
# job failed (71 on the server by 2026-11-16) before it sent a thing.
RUN install-php-extensions gd pdo_pgsql pcntl opcache redis gmp bcmath
# [X45] OPcache: Laravel compiled once per start. The code never changes inside the container, so files are not
# checked again. [Sprint 51 B5] And PHP never says its version.
RUN { echo 'opcache.enable=1'; echo 'opcache.enable_cli=1'; echo 'opcache.memory_consumption=128'; \
      echo 'opcache.interned_strings_buffer=16'; echo 'opcache.max_accelerated_files=20000'; \
      echo 'opcache.validate_timestamps=0'; echo 'realpath_cache_size=4096K'; echo 'realpath_cache_ttl=600'; \
      echo 'expose_php=Off'; echo 'memory_limit=256M'; echo 'upload_max_filesize=20M'; echo 'post_max_size=24M'; } \
      > "$PHP_INI_DIR/conf.d/zz-legends-speed.ini"
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY backend ./
COPY data /app/data
# [Sprint 71 N6] The app's version in this code (the admin panel says when the app players download is older).
COPY mobile/pubspec.yaml /app/mobile/pubspec.yaml
COPY --from=vendor /app/backend/vendor ./vendor
COPY --from=web /app/web/dist ./public-web
RUN composer dump-autoload --optimize --no-dev \
 && cp -r public-web/. public/ && rm -rf public-web \
 && rm -rf public/downloads && ln -s ../storage/app/downloads/bundled public/downloads && mkdir -p storage/app/downloads \
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
 && mkdir -p public/crests \
 && chown -R www-data:www-data storage database bootstrap/cache public/crests \
 && mkdir -p /data/caddy /config/caddy && chown -R www-data:www-data /data /config
# [X106] public/crests is where data:crests writes the clubs' crests at each start (Sprint 58 B2), as www-data: public/
# itself stays root's, so the folder was never made and every start said "Crests: failed" (the crests then went through
# Laravel's old route, with no year-long cache).

# [Sprint 52 B7] public/downloads is a link into the downloads volume (deploy/vps/compose.yml): the Android app that
# ships with the site lives on the server (deploy.sh moved it there once), not in the repository and the image (44 MB).
# Caddy follows the link and sends the file itself. A newer app comes through the admin panel's upload (AppReleases).

# The start script: the public address, sign-in, email and Google from the run-time variables, the configuration
# cached then (not here, before they are known), and the queue, scheduler, live matches and Reverb.
COPY deploy/docker/start.sh /app/start.sh
COPY deploy/docker/router.php /app/backend/router.php
COPY deploy/docker/Caddyfile /etc/caddy/Caddyfile
COPY deploy/docker/caddy-headers.php /app/caddy-headers.php
# [Sprint 52 B5] One image, several services (deploy/vps/compose.yml): ROLE says which (web, queue, scheduler,
# matches, reverb). Caddy keeps its own files where www-data may write.
ENV PORT=8000 ROLE=web XDG_DATA_HOME=/data XDG_CONFIG_HOME=/config
EXPOSE 8000
USER www-data
CMD ["sh", "/app/start.sh"]
