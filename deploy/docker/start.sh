#!/bin/sh
# The container's start (Dockerfile CMD), on our server (deploy/vps/compose.yml) or anywhere with docker run.
# PUBLIC_URL is the site's address, so the settings that depend on it are made here, not when the image is built.
# Exported variables win over backend/.env (Laravel never overwrites a variable that is already set).
#
# [Sprint 52 B5] One image, a service per job (compose.yml): ROLE=web (the site and the API: the only one that
# migrates and imports), queue, scheduler, matches or reverb. Each runs in the foreground, so Docker restarts the one
# that stops and keeps its log. Without Redis (REDIS_HOST unset: a plain docker run, CI's try-out) the web container
# runs the four others beside it, as before.
set -e
cd /app/backend
ROLE="${ROLE:-web}"

if [ -n "${PUBLIC_URL:-}" ]; then
  host="${PUBLIC_URL#https://}"
  export APP_URL="$PUBLIC_URL"
  export FRONTEND_URL="$APP_URL"
  export GOOGLE_REDIRECT_URI="$APP_URL/auth/google/callback"
  # Sign-in: the session cookie counts only for these hosts (without it the web signs in, then is a guest).
  export SANCTUM_STATEFUL_DOMAINS="${host},localhost,localhost:8000,127.0.0.1,127.0.0.1:8000"
  export SESSION_SECURE_COOKIE=true
  # [Sprint 52 B8] Only the server's nginx reaches the container (through Docker's network): trust its X-Forwarded-*
  # headers (https, the public host, the player's address), and nobody else's. compose.yml sets the network's range.
  export TRUSTED_PROXIES="${TRUSTED_PROXIES:-127.0.0.1,::1}"
fi

# Real emails [X8]. [X89] The game's own Gmail only (the owner's decision 2026-11-02: "we do not use Brevo"): every email
# goes out through Gmail's own servers (smtp.gmail.com, TLS on 587), from game.legend.manager@gmail.com under the game's
# name, with its app password set on the server (legends-set GMAIL_APP_PASSWORD). Sent anywhere else in a gmail.com name
# (Brevo, Resend), Gmail sees a message that never left Google and files it as spam (DMARC), so no other way is taken
# even when its key is still on the server. Without the password the emails go to the log.
export GMAIL_ADDRESS="${GMAIL_ADDRESS:-game.legend.manager@gmail.com}"
export MAIL_FROM_NAME="${MAIL_FROM_NAME:-Game Legend Manager}"
if [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  export MAIL_MAILER=smtp MAIL_SCHEME=smtp MAIL_HOST=smtp.gmail.com MAIL_PORT=587
  export MAIL_USERNAME="$GMAIL_ADDRESS" MAIL_FROM_ADDRESS="$GMAIL_ADDRESS" MAIL_REPLY_TO_ADDRESS="$GMAIL_ADDRESS"
  MAIL_PASSWORD=$(printf '%s' "$GMAIL_APP_PASSWORD" | tr -d ' ')
  export MAIL_PASSWORD
  [ -n "${BREVO_API_KEY:-}${RESEND_API_KEY:-}" ] && echo "Emails: BREVO_API_KEY or RESEND_API_KEY on the server is not used (Gmail only, X89)."
else
  export MAIL_MAILER=log
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

# [Sprint 52 B4] Redis (compose.yml) for the cache, the sessions and the queue: in memory, shared by every service.
if [ -n "${REDIS_HOST:-}" ]; then
  export CACHE_STORE=redis SESSION_DRIVER=redis QUEUE_CONNECTION=redis REDIS_CLIENT=phpredis
fi

# The other services: the settings cached for this container, then their one job in the foreground. The web service
# has migrated the database before they start (compose.yml waits for it to be healthy).
if [ "$ROLE" != web ]; then
  php artisan config:cache > /dev/null
  php artisan event:cache > /dev/null
  case "$ROLE" in
    queue)
      # The jobs still waiting in the old database queue (before Redis) run first, once.
      php artisan queue:work database --stop-when-empty --tries=1 || true
      exec php artisan queue:work --tries=1 --sleep=3 ;;
    scheduler) exec php artisan schedule:work ;;
    matches) exec php artisan matches:run ;;
    reverb) exec php artisan reverb:start ;;
    *) echo "Unknown ROLE: $ROLE"; exit 1 ;;
  esac
fi

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
# [Sprint 29] The national teams from the players' nationalities (adds new countries, refreshes their strength).
php artisan data:nations || echo "National teams: failed, continuing"
# [X45] Without Redis, the sessions in the container's own SQLite file beside the cache: no database trip on every
# request. A restart signs nobody out for long: the remember-me cookie (on by default) signs them back in.
[ -n "${REDIS_HOST:-}" ] || export SESSION_DRIVER=database SESSION_CONNECTION=cache_db
php artisan config:cache
php artisan route:cache
php artisan event:cache
php artisan view:cache

# [X99] Each worker in its own loop: one that stops (an error, out of memory, the database gone for a moment) is
# started again in a few seconds, written in its log, instead of the matches or live updates stopping in silence.
keep() {
  log="$1"; shift
  while true; do
    "$@" >> "storage/logs/$log" 2>&1
    code=$?
    echo "$(date -u '+%F %T') $* stopped (exit $code), starting again in 5s" >> "storage/logs/$log"
    sleep 5
  done
}
if [ -z "${REDIS_HOST:-}" ]; then
  keep queue.log php artisan queue:work --tries=1 --sleep=3 &
  keep schedule.log php artisan schedule:work &
  keep matches.log php artisan matches:run &
  # [X48] Live updates: Reverb beside the game (the server's nginx sends /app and /apps to it).
  if [ "${BROADCAST_CONNECTION:-}" = reverb ]; then
    keep reverb.log php artisan reverb:start &
    echo "Live updates: Reverb on port ${REVERB_SERVER_PORT:-8080}"
  fi
else
  echo "Services: queue, scheduler, matches and Reverb in their own containers; cache, sessions and queue in Redis"
fi

echo "Legends: ${APP_URL:-http://localhost:${PORT}}"
case "${MAIL_MAILER:-log}" in
  brevo|resend) echo "Emails: through ${MAIL_MAILER} (HTTPS) from ${MAIL_FROM_ADDRESS}" ;;
  smtp) echo "Emails: through Gmail SMTP from ${MAIL_FROM_ADDRESS}" ;;
  *) echo "Emails: to storage/logs/laravel.log" ;;
esac
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then echo "Google sign-in: on"; else echo "Google sign-in: off"; fi
if [ -n "$pg" ]; then echo "Saved game: in PostgreSQL, kept across every restart and deploy"; else echo "Saved game: off, the SQLite file is wiped on every restart (DATABASE_URL for a real game)"; fi

# [Sprint 52 B3] The web server: FrankenPHP (deploy/docker/Caddyfile). Caddy sends the built files, router.php the
# pages and Laravel the rest; the security headers of the files from the one policy (App\Http\Security\SecurityPolicy).
php /app/caddy-headers.php > "${XDG_CONFIG_HOME:-/config}/caddy/security-headers.caddy"
exec frankenphp run --config /etc/caddy/Caddyfile
