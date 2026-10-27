#!/bin/sh
# The container's start (Dockerfile CMD), on our server (deploy/vps/compose.yml) or anywhere with docker run.
# PUBLIC_URL is the site's address, so the settings that depend on it are made here, not when the image is built.
# Exported variables win over backend/.env (Laravel never overwrites a variable that is already set).
set -e
cd /app/backend

if [ -n "${PUBLIC_URL:-}" ]; then
  host="${PUBLIC_URL#https://}"
  export APP_URL="$PUBLIC_URL"
  export FRONTEND_URL="$APP_URL"
  export GOOGLE_REDIRECT_URI="$APP_URL/auth/google/callback"
  # Sign-in: the session cookie counts only for these hosts (without it the web signs in, then is a guest).
  export SANCTUM_STATEFUL_DOMAINS="${host},localhost,localhost:8000,127.0.0.1,127.0.0.1:8000"
  export SESSION_SECURE_COOKIE=true
  # Only the server's nginx reaches the container: trust its X-Forwarded-* headers (https and the public host).
  export TRUSTED_PROXIES='*'
fi

# Real emails [X8]: Gmail's SMTP (GMAIL_ADDRESS and its app password), or over HTTPS with BREVO_API_KEY (free, 300 a
# day) or RESEND_API_KEY (free, needs a domain of ours). Without any of them the emails go to the log.
if [ -n "${BREVO_API_KEY:-}" ]; then
  export MAIL_MAILER=brevo MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-${GMAIL_ADDRESS:-}}"
elif [ -n "${RESEND_API_KEY:-}" ]; then
  export MAIL_MAILER=resend MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-onboarding@resend.dev}"
elif [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  export MAIL_MAILER=smtp MAIL_HOST=smtp.gmail.com MAIL_PORT=587
  export MAIL_USERNAME="$GMAIL_ADDRESS" MAIL_FROM_ADDRESS="$GMAIL_ADDRESS"
  MAIL_PASSWORD=$(printf '%s' "$GMAIL_APP_PASSWORD" | tr -d ' ')
  export MAIL_PASSWORD
fi

# One key for every deploy, so sign-ins and encrypted values survive it.
if [ -n "${APP_KEY_SEED:-}" ]; then
  APP_KEY=$(php -r 'echo "base64:".base64_encode(hash("sha256", getenv("APP_KEY_SEED"), true));')
  export APP_KEY
fi

# The game in PostgreSQL [X43, X48]: DATABASE_URL is its connection string (the server's own PostgreSQL in
# compose.yml). Without it the game runs on the image's SQLite file, wiped on every restart (a try-out only).
pg=
if [ -n "${DATABASE_URL:-}" ]; then
  export DB_CONNECTION=pgsql DB_URL="$DATABASE_URL" DB_QUEUE_CONNECTION=pgsql DB_SSLMODE="${DB_SSLMODE:-require}"
  # [X45] Each web worker keeps its connection between requests, and skips a setup statement it does not need.
  export DB_PERSISTENT=true DB_SEARCH_PATH=
  pg=1
fi

mkdir -p storage/logs

# A copy of the game as it is before this deploy's migrations [X33], kept in the backups volume and downloadable from
# the admin panel (النسخ). The migrations only add (tests/Feature/MigrationSafetyTest.php), but a copy costs nothing.
if [ -n "$pg" ]; then
  # [X47] A database with a game: a copy first. An empty one: its tables are made here and the clubs and players
  # imported below, a new game.
  if php artisan db:to-supabase --check; then
    php artisan db:backup --keep=5 || echo "Backup before migrating: failed, continuing"
  else
    echo "Database: empty, a new game starts"
  fi
  php artisan migrate --force
  # Row level security on every table: harmless here, and it keeps Supabase's public API out if it is used again.
  php artisan db:close-api
else
  php artisan migrate --force
fi
php artisan data:import --add
# [X45] The sessions in the server's own SQLite file beside the cache: no database trip on every request. A restart
# signs nobody out for long: the remember-me cookie (on by default) signs them back in.
export SESSION_DRIVER=database SESSION_CONNECTION=cache_db
php artisan config:cache
php artisan route:cache
php artisan event:cache
php artisan view:cache

php artisan queue:work --tries=1 --sleep=3 >> storage/logs/queue.log 2>&1 &
php artisan schedule:work >> storage/logs/schedule.log 2>&1 &
php artisan matches:run >> storage/logs/matches.log 2>&1 &
# [X48] Live updates: Reverb beside the game (the server's nginx sends /app and /apps to it).
if [ "${BROADCAST_CONNECTION:-}" = reverb ]; then
  php artisan reverb:start >> storage/logs/reverb.log 2>&1 &
  echo "Live updates: Reverb on port ${REVERB_SERVER_PORT:-8080}"
fi

echo "Legends: ${APP_URL:-http://localhost:${PORT}}"
case "${MAIL_MAILER:-log}" in
  brevo|resend) echo "Emails: through ${MAIL_MAILER} (HTTPS) from ${MAIL_FROM_ADDRESS}" ;;
  smtp) echo "Emails: through Gmail SMTP from ${MAIL_FROM_ADDRESS}" ;;
  *) echo "Emails: to storage/logs/laravel.log" ;;
esac
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then echo "Google sign-in: on"; else echo "Google sign-in: off"; fi
if [ -n "$pg" ]; then echo "Saved game: in PostgreSQL, kept across every restart and deploy"; else echo "Saved game: off, the SQLite file is wiped on every restart (DATABASE_URL for a real game)"; fi

# The web server [X45]: PHP's own, PHP_CLI_SERVER_WORKERS (Dockerfile) at once, with router.php sending the built
# files and the app's pages without Laravel.
exec php -S 0.0.0.0:"${PORT}" -t public router.php
