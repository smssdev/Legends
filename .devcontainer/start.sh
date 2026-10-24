#!/usr/bin/env bash
# Runs every time the Codespace opens: brings it up to date with main, rebuilds
# the web app when the code changed, then serves the game on port 8000 with the
# workers the game needs (queue, scheduler, live matches).
cd "$(dirname "$0")/.."
if [ -z "$(git status --porcelain)" ]; then
  git fetch --quiet origin main || true
  [ "$(git rev-parse --abbrev-ref HEAD)" = main ] || git checkout --quiet main || true
  git pull --quiet --ff-only origin main || echo "Could not update from main; running the current copy."
else
  echo "Local changes found: not updating from main."
fi
# The Codespace's address, sign-in and email settings (read after the pull, so a new env.sh counts).
# shellcheck source=env.sh
. .devcontainer/env.sh
cd backend
stamp=storage/.built-commit
if [ "$(cat "$stamp" 2>/dev/null)" != "$(git rev-parse HEAD)" ]; then
  echo "Updating the game to $(git log -1 --format='%h %s')"
  composer install --no-interaction --prefer-dist --no-progress --quiet
  php artisan migrate --force
  composer build-web
  git rev-parse HEAD > "$stamp"
fi
php artisan config:clear --quiet || true

# Opening the Codespace again restarts everything instead of starting it twice.
pkill -f 'artisan (serve|queue:work|schedule:work|matches:run)' 2>/dev/null || true
pkill -f 'Foundation/resources/server.php' 2>/dev/null || true
sleep 1
mkdir -p storage/logs
nohup php artisan queue:work --tries=1 --sleep=1 >> storage/logs/queue.log 2>&1 &
nohup php artisan schedule:work >> storage/logs/schedule.log 2>&1 &
nohup php artisan matches:run >> storage/logs/matches.log 2>&1 &

echo
echo "Legends: ${APP_URL:-http://localhost:8000}"
if [ -n "${MAIL_HOST:-}" ]; then
  echo "Emails: sent through Gmail from ${MAIL_FROM_ADDRESS}"
else
  echo "Emails: written to backend/storage/logs/laravel.log (add the GMAIL_ADDRESS and GMAIL_APP_PASSWORD secrets to send them)"
fi
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
  echo "Google sign-in: on, return address ${GOOGLE_REDIRECT_URI:-}"
else
  echo "Google sign-in: off (add the GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET secrets)"
fi
# --no-reload: without it "serve" drops the variables above before starting PHP's server.
exec php artisan serve --host=0.0.0.0 --port=8000 --no-reload
