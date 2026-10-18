# One image with everything for the simulator demo: the Laravel API, the built
# Vue app and the imported club data. Used by Render (render.yaml) and runnable
# anywhere with: docker build -t legends . && docker run -p 8000:8000 legends
# Free hosts wipe the disk on restart: fine for the simulator, not for leagues
# (those need the home server in PLAN 2.19).

FROM node:22-alpine AS web
WORKDIR /app
COPY docs/design ./docs/design
COPY web/package.json web/package-lock.json ./web/
RUN cd web && npm ci
COPY web ./web
RUN cd web && npm run build

FROM composer:2 AS vendor
WORKDIR /app/backend
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress --no-scripts --no-autoloader

FROM php:8.4-cli-alpine
WORKDIR /app/backend
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY backend ./
COPY data /app/data
COPY --from=vendor /app/backend/vendor ./vendor
COPY --from=web /app/web/dist ./public-web
RUN composer dump-autoload --optimize --no-dev \
 && cp -r public-web/. public/ && rm -rf public-web \
 && cp .env.example .env \
 && sed -i 's/^APP_ENV=.*/APP_ENV=demo/; s/^APP_DEBUG=.*/APP_DEBUG=false/' .env \
 && echo "SIMULATOR_ENABLED=true" >> .env \
 && php artisan key:generate --force \
 && php artisan migrate --force \
 && php artisan data:import \
 && php artisan config:cache \
 && chown -R www-data:www-data storage database bootstrap/cache
ENV PORT=8000 PHP_CLI_SERVER_WORKERS=4
EXPOSE 8000
USER www-data
CMD ["sh", "-c", "php artisan serve --host=0.0.0.0 --port=${PORT}"]
