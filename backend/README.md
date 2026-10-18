# Legends API

Laravel 12 API (prefix `/api/v1`) for the web app in `../web` (and the Flutter app after v1.0).

- **SQLite, three files** in `database/`: `legends.sqlite` (data), `cache.sqlite`, `queue.sqlite`.
  WAL, `busy_timeout` 5000, foreign keys, and write transactions open with `BEGIN IMMEDIATE`
  (on PHP 8.3 through `App\Database\ImmediatePdo`; PHP 8.4 is recommended). Files are created on first use.
- **Game values** in `config/game.php` (docs/PLAN.md section 3).

```bash
composer setup   # install, .env, key, migrate, web dependencies
composer dev     # API :8000 + queue + scheduler + web :5173
composer test    # tests run on real SQLite files (database/testing*.sqlite)
composer fresh   # wipe data, cache and queue, then migrate
vendor/bin/pint  # code style
```
