#!/usr/bin/env bash
# One-time Codespace setup: dependencies, databases, real club data, built web app.
set -euo pipefail
cd "$(dirname "$0")/../backend"
composer install --no-interaction --prefer-dist --no-progress
[ -f .env ] || cp .env.example .env
php artisan key:generate --force
php artisan migrate --force
php artisan data:import
composer build-web
git rev-parse HEAD > storage/.built-commit
echo
echo "Ready: the simulator is at port 8000, path /sim"
echo "For live frontend work run: composer dev   (Vite on port 5173)"
