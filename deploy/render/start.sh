#!/bin/sh
# The container's start on Render (Dockerfile CMD). Render gives the service's public address at run time
# (RENDER_EXTERNAL_URL), so the settings that depend on it are made here, not when the image is built.
# Exported variables win over backend/.env (Laravel never overwrites a variable that is already set).
set -e
cd /app/backend

if [ -n "${RENDER_EXTERNAL_URL:-}" ]; then
  host="${RENDER_EXTERNAL_HOSTNAME:-${RENDER_EXTERNAL_URL#https://}}"
  export APP_URL="$RENDER_EXTERNAL_URL"
  export FRONTEND_URL="$APP_URL"
  export GOOGLE_REDIRECT_URI="$APP_URL/auth/google/callback"
  # Sign-in: the session cookie counts only for these hosts (without it the web signs in, then is a guest).
  export SANCTUM_STATEFUL_DOMAINS="${host},localhost,localhost:8000,127.0.0.1,127.0.0.1:8000"
  export SESSION_SECURE_COOKIE=true
  # Only Render's proxy reaches the container: trust its X-Forwarded-* headers (https and the public host).
  export TRUSTED_PROXIES='*'
fi

# Real emails through Gmail (free): GMAIL_ADDRESS and GMAIL_APP_PASSWORD in Render's Environment
# (an app password from myaccount.google.com/apppasswords). Without them the emails go to the log.
if [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  export MAIL_MAILER=smtp MAIL_HOST=smtp.gmail.com MAIL_PORT=587
  export MAIL_USERNAME="$GMAIL_ADDRESS" MAIL_FROM_ADDRESS="$GMAIL_ADDRESS"
  MAIL_PASSWORD=$(printf '%s' "$GMAIL_APP_PASSWORD" | tr -d ' ')
  export MAIL_PASSWORD
fi
# Google sign-in: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in Render's Environment are read as they are.

mkdir -p storage/logs
php artisan migrate --force
# Cache the configuration now that the run-time variables are known.
php artisan config:cache

# The workers the game needs: the queue, the scheduler (training, scout, seasons) and the live matches.
php artisan queue:work --tries=1 --sleep=1 >> storage/logs/queue.log 2>&1 &
php artisan schedule:work >> storage/logs/schedule.log 2>&1 &
php artisan matches:run >> storage/logs/matches.log 2>&1 &

echo "Legends: ${APP_URL:-http://localhost:${PORT}}"
if [ -n "${MAIL_HOST:-}" ]; then echo "Emails: through Gmail from ${MAIL_FROM_ADDRESS}"; else echo "Emails: to storage/logs/laravel.log"; fi
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then echo "Google sign-in: on, return address ${GOOGLE_REDIRECT_URI:-}"; else echo "Google sign-in: off"; fi
# --no-reload: without it "serve" drops the variables above before starting PHP's server.
exec php artisan serve --host=0.0.0.0 --port="${PORT}" --no-reload
