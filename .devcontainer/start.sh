#!/usr/bin/env bash
# Runs every time the Codespace opens: brings it up to date with main, rebuilds
# the web app when the code changed, then serves the game on port 8000.
cd "$(dirname "$0")/.."
if [ -z "$(git status --porcelain)" ]; then
  git fetch --quiet origin main || true
  [ "$(git rev-parse --abbrev-ref HEAD)" = main ] || git checkout --quiet main || true
  git pull --quiet --ff-only origin main || echo "Could not update from main; running the current copy."
else
  echo "Local changes found: not updating from main."
fi
cd backend
stamp=storage/.built-commit
if [ "$(cat "$stamp" 2>/dev/null)" != "$(git rev-parse HEAD)" ]; then
  echo "Updating the game to $(git log -1 --format='%h %s')"
  composer install --no-interaction --prefer-dist --no-progress --quiet
  php artisan migrate --force
  composer build-web
  git rev-parse HEAD > "$stamp"
fi
exec php artisan serve --host=0.0.0.0 --port=8000
