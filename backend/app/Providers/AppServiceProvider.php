<?php

namespace App\Providers;

use App\Database\SQLiteConnector;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        if (PHP_VERSION_ID < 80400) {
            $this->app->bind('db.connector.sqlite', SQLiteConnector::class);
        }
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->ensureSqliteFiles();
    }

    /**
     * SQLite refuses to open a missing file, so create the data, cache and
     * queue files on first use (fresh clones, CI, tests).
     */
    private function ensureSqliteFiles(): void
    {
        foreach (config('database.connections') as $connection) {
            $path = $connection['database'] ?? null;

            if (($connection['driver'] ?? null) === 'sqlite' && $path && $path !== ':memory:'
                && ! file_exists($path) && is_dir(dirname($path))) {
                touch($path);
            }
        }
    }
}
