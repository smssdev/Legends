<?php

namespace App\Providers;

use App\Ads\DisabledVerifier;
use App\Ads\HouseAds;
use App\Ads\RewardVerifier;
use App\Database\PostgresConnection;
use App\Database\SQLiteConnector;
use App\Mail\ApiTransport;
use App\Support\ServerHealth;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Connection;
use Illuminate\Database\Events\TransactionBeginning;
use Illuminate\Http\Request;
use Illuminate\Queue\Events\Looping;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /** The key of the game's one write lock on PostgreSQL [X43]. */
    public const WRITE_LOCK = 4_204_201;

    /**
     * Register any application services.
     */
    public function register(): void
    {
        // [X43] PostgreSQL answers as SQLite does (booleans as 1 or 0).
        Connection::resolverFor('pgsql', fn ($pdo, $database, $prefix, $config) => new PostgresConnection($pdo, $database, $prefix, $config));
        if (PHP_VERSION_ID < 80400) {
            $this->app->bind('db.connector.sqlite', SQLiteConnector::class);
        }
        // [Sprint 21 E9, Sprint 20 S4] The rewarded ads' provider: our own (house) by default, none to switch it off.
        $this->app->bind(RewardVerifier::class, fn () => match (config('game.ads.driver')) {
            'house' => new HouseAds,
            default => new DisabledVerifier,
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->ensureSqliteFiles();

        // [X43] On PostgreSQL (Supabase) every transaction takes one lock first, as SQLite's BEGIN IMMEDIATE did: the
        // game's writes stay one at a time, so every reservation written for SQLite (a read, a check, then a write in
        // one transaction) holds there too. Released by the commit or the rollback.
        Event::listen(TransactionBeginning::class, function (TransactionBeginning $e) {
            if ($e->connection->getDriverName() === 'pgsql' && $e->connection->transactionLevel() === 1) {
                $e->connection->select('select pg_advisory_xact_lock(?)', [self::WRITE_LOCK]);
            }
        });

        // Emails over HTTPS where the host blocks SMTP [X8].
        Mail::extend('api', fn (array $config) => new ApiTransport((string) $config['service'], (string) $config['key']));

        // The queue worker's sign of life for the health check [Sprint 21 B2].
        Event::listen(Looping::class, fn () => ServerHealth::beat('queue'));

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
