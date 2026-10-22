<?php

namespace App\Providers;

use App\Database\SQLiteConnector;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

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

        // Sign-in, sign-up and password attempts: 5 a minute per email, 20 per address [Sprint 10 B3].
        RateLimiter::for('auth', fn (Request $request) => [
            Limit::perMinute(5)->by('email:'.Str::lower((string) $request->input('email', $request->user()?->email)).'|'.$request->ip()),
            Limit::perMinute(20)->by('ip:'.$request->ip()),
        ]);

        // Tries at a league code, per account [PLAN 2.1]: guessing codes stays slow.
        RateLimiter::for('league-code', fn (Request $request) => Limit::perMinute(config('game.league.join_attempts_per_minute'))
            ->by('league-code:'.($request->user()?->id ?? $request->ip())));
        // Named, so it counts apart from the general limit on the same routes.
        RateLimiter::for('league-create', fn (Request $request) => Limit::perMinute(10)->by('league-create:'.($request->user()?->id ?? $request->ip())));
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
