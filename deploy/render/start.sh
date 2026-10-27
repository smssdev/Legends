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

# Real emails [X8]. Render's free plan blocks the SMTP ports (25, 465, 587), so Gmail's SMTP cannot work here:
# the emails go over HTTPS instead. BREVO_API_KEY (free, 300 a day; MAIL_FROM_ADDRESS is the sender verified in
# Brevo, a Gmail address works) or RESEND_API_KEY (free, needs a domain of ours). Gmail's SMTP is kept for hosts
# that allow it (the home server, Codespaces). Without any of them the emails go to the log.
if [ -n "${BREVO_API_KEY:-}" ]; then
  export MAIL_MAILER=brevo MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-${GMAIL_ADDRESS:-}}"
elif [ -n "${RESEND_API_KEY:-}" ]; then
  export MAIL_MAILER=resend MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-onboarding@resend.dev}"
elif [ -n "${GMAIL_ADDRESS:-}" ] && [ -n "${GMAIL_APP_PASSWORD:-}" ]; then
  echo "Emails: Gmail SMTP is blocked on Render's free plan; set BREVO_API_KEY instead (docs/PLAN.md 8.1)"
  export MAIL_MAILER=smtp MAIL_HOST=smtp.gmail.com MAIL_PORT=587
  export MAIL_USERNAME="$GMAIL_ADDRESS" MAIL_FROM_ADDRESS="$GMAIL_ADDRESS"
  MAIL_PASSWORD=$(printf '%s' "$GMAIL_APP_PASSWORD" | tr -d ' ')
  export MAIL_PASSWORD
fi

if [ -n "${APP_KEY_SEED:-}" ]; then
  APP_KEY=$(php -r 'echo "base64:".base64_encode(hash("sha256", getenv("APP_KEY_SEED"), true));')
  export APP_KEY
fi

# [X43] The game in Supabase (PostgreSQL, free): DATABASE_URL is its connection string (Supabase → Connect → Session
# pooler). Then the database is no longer on Render's disk, nothing is copied to B2, and nothing is lost on a restart.
# The first start with it moves the league from B2 into Supabase once (db:to-supabase); after that B2 is only read
# again if Supabase is ever empty. The cache stays a file here (it rebuilds itself).
supabase=
if [ -n "${DATABASE_URL:-}" ]; then
  export DB_CONNECTION=pgsql DB_URL="$DATABASE_URL" DB_QUEUE_CONNECTION=pgsql DB_SSLMODE="${DB_SSLMODE:-require}"
  # [X45] Each web worker keeps its connection to Supabase between requests (no new TLS handshake and sign-in each
  # time), and skips the setup statement Supabase does not need (the public schema is its default).
  export DB_PERSISTENT=true DB_SEARCH_PATH=
  supabase=1
fi

saved=
if [ -n "${B2_BUCKET:-}" ] && [ -n "${B2_ENDPOINT:-}" ] && [ -n "${B2_KEY_ID:-}" ] && [ -n "${B2_APPLICATION_KEY:-}" ]; then
  endpoint="${B2_ENDPOINT#https://}"
  endpoint="${endpoint%/}"
  export LITESTREAM_BUCKET="$B2_BUCKET" LITESTREAM_ENDPOINT="https://$endpoint"
  region=$(printf '%s' "$endpoint" | sed -n 's/^s3\.\([^.]*\)\.backblazeb2\.com$/\1/p')
  export LITESTREAM_REGION="${region:-us-east-1}"
  export LITESTREAM_ACCESS_KEY_ID="$B2_KEY_ID" LITESTREAM_SECRET_ACCESS_KEY="$B2_APPLICATION_KEY"
  
  # RESTORE_AT (an RFC 3339 time in Render's Environment, e.g. 2026-10-26T18:30:00Z) brings the game back as it was
  # then, from B2's history (three days); remove it after that deploy, or every restart goes back to it.
  at=
  if [ -n "${RESTORE_AT:-}" ]; then
    at="-timestamp $RESTORE_AT"
    echo "Saved game: going back to $RESTORE_AT (remove RESTORE_AT from Render's Environment after this deploy)"
  fi

  # Both databases from B2 into place, or nothing moved (each comes down beside its file first).
  dbs="legends queue"
  [ -n "$supabase" ] && dbs="legends"
  restore_all() {
    for db in $dbs; do
      file="database/$db.sqlite"
      rm -f "$file.restore"
      # shellcheck disable=SC2086
      if ! litestream restore -config /app/litestream.yml -if-replica-exists $at -o "$file.restore" "/app/backend/$file" 2> /tmp/restore.err; then
        cat /tmp/restore.err
        if grep -q "cap exceeded" /tmp/restore.err; then
          echo "Saved game: B2 refused (its daily cap). Raise the cap of Class B and Class C transactions in Backblaze"
          echo "  (Caps & Alerts), or it comes back by itself after midnight UTC."
        fi
        return 1
      fi
    done
    for db in $dbs; do
      file="database/$db.sqlite"
      if [ -f "$file.restore" ]; then
        rm -f "$file" "$file-wal" "$file-shm" "$file.restore.tmp"*
        mv "$file.restore" "$file"
        echo "Saved game: $db.sqlite brought back from B2"
      fi
    done
  }

  # [X39] When B2 cannot be read, the game never starts without its save: playing on would lose everything done
  # (nothing would be copied) or start an empty game over the league. The site shows a maintenance page instead
  # (deploy/render/maintenance.php, so Render keeps it up) and tries B2 again every 10 minutes; once it answers, the
  # page goes and the game starts with the league as it was, without a new deploy.
  # On Supabase B2 is never read [X47]: the move from B2 (X43) is done, and a new, empty Supabase starts a new game
  # (the owner's decision, 2026-10-27) instead of waiting on an old copy.
  if [ -n "$supabase" ]; then
    restore_all() { return 0; }
    echo "Saved game: in Supabase (B2 not needed)"
  fi
  if ! restore_all; then
    php -S 0.0.0.0:"${PORT}" /app/maintenance.php > /dev/null 2>&1 &
    page=$!
    until restore_all; do
      echo "Saved game: B2 still refuses; the maintenance page stays, trying again in 10 minutes"
      sleep 600
    done
    kill "$page" 2> /dev/null || true
    sleep 1
  fi
  saved=1
fi

mkdir -p storage/logs

# A copy of the game as it is before this deploy's migrations, downloadable from the admin panel (النسخ) until the
# next restart [X33]. The migrations only add (tests/Feature/MigrationSafetyTest.php), but a copy costs nothing.
if [ -n "$supabase" ]; then
  # [X47] A Supabase with a game: a copy first. An empty one: its tables are made here and the clubs and players
  # imported below, a new game (no copy from B2 or the image's file, nothing to wait for).
  if php artisan db:to-supabase --check; then
    php artisan db:backup --keep=5 || echo "Backup before migrating: failed, continuing"
  else
    echo "Supabase: empty, a new game starts"
  fi
  php artisan migrate --force
  # Supabase's public API never sees the game's tables (its public key is not a secret).
  php artisan db:close-api
else
  if [ -n "$saved" ]; then php artisan db:backup --keep=5 || echo "Backup before migrating: failed, continuing"; fi
  php artisan migrate --force
fi
php artisan data:import --add
# [X45] The sessions in this server's own SQLite file beside the cache, not in Supabase: no network trip on every
# request. A restart signs nobody out for long: the remember-me cookie (on by default) signs them back in.
export SESSION_DRIVER=database SESSION_CONNECTION=cache_db
php artisan config:cache
php artisan route:cache
php artisan event:cache
php artisan view:cache

php artisan queue:work --tries=1 --sleep=3 >> storage/logs/queue.log 2>&1 &
php artisan schedule:work >> storage/logs/schedule.log 2>&1 &
php artisan matches:run >> storage/logs/matches.log 2>&1 &

echo "Legends: ${APP_URL:-http://localhost:${PORT}}"
case "${MAIL_MAILER:-log}" in
  brevo|resend) echo "Emails: through ${MAIL_MAILER} (HTTPS) from ${MAIL_FROM_ADDRESS}" ;;
  smtp) echo "Emails: through Gmail SMTP from ${MAIL_FROM_ADDRESS}" ;;
  *) echo "Emails: to storage/logs/laravel.log" ;;
esac
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then echo "Google sign-in: on"; else echo "Google sign-in: off"; fi

# The web server [X45]: PHP's own, PHP_CLI_SERVER_WORKERS (Dockerfile) at once, with router.php sending the built
# files and the app's pages without Laravel. Where the game is saved decides only what wraps it.
if [ -n "$supabase" ]; then
  echo "Saved game: in Supabase, kept across every restart and deploy"
  exec php -S 0.0.0.0:"${PORT}" -t public router.php
elif [ -n "$saved" ]; then
  echo "Saved game: every change copied to B2 ($LITESTREAM_BUCKET)"
  exec litestream replicate -config /app/litestream.yml -exec "php -S 0.0.0.0:${PORT} -t public router.php"
else
  echo "Saved game: off, the data is wiped on every restart (B2_* in Render's Environment)"
  exec php -S 0.0.0.0:"${PORT}" -t public router.php
fi
