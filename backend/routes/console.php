<?php

use App\Support\ServerHealth;
use Illuminate\Support\Facades\Schedule;

// The scheduler runs every minute on the server (Windows Task Scheduler or cron).
// Leagues start at the time their owner chose [PLAN 2.1].
Schedule::command('leagues:start')->everyMinute()->withoutOverlapping();
// Absence [PLAN 2.2]: a warning at 48 hours, and 3 days away hands the club back to a bot.
Schedule::command('leagues:absence')->everyMinute()->withoutOverlapping();
// Before each match: the referee at 30 minutes, the lock (with the automatic fix) at 5 [PLAN 2.13].
Schedule::command('matches:prepare')->everyMinute()->withoutOverlapping();
// The market pool renews when each transfer window opens [PLAN 2.7, Sprint 24].
Schedule::command('market:renew')->everyMinute()->withoutOverlapping();
// The scouts' reports, coach online or not [Sprint 26].
Schedule::command('scout:due')->everyMinute()->withoutOverlapping();
// Training sessions, coach online or not [Sprint 27].
Schedule::command('training:tick')->everyMinute()->withoutOverlapping();
// The stadium's parts, coach online or not [Sprint 29].
Schedule::command('stadium:due')->everyMinute()->withoutOverlapping();

// The scheduler's own sign of life for the health check (the watchdog runs that check apart) [Sprint 21 B2].
Schedule::call(fn () => ServerHealth::beat('scheduler'))->everyMinute()->name('heartbeat');

// Daily backup of the three SQLite files at 04:00 Cairo time, the quietest hour.
Schedule::command('db:backup')->dailyAt('04:00')->timezone('Africa/Cairo');

// docs/ENGINE.md 9: the full calibration runs every night on the home server (not on CI minutes).
// The reports land in storage/app/balance/ for the next morning.
if (config('game.balance.nightly')) {
    Schedule::command('sim:balance --n=5000 --favourite=1000 --report='.storage_path('app/balance/latest.json'))
        ->dailyAt('03:00')->timezone('Africa/Cairo')->withoutOverlapping()->runInBackground()
        ->appendOutputTo(storage_path('logs/balance.log'));
    Schedule::command('sim:knobs --n=2000')->dailyAt('03:30')->timezone('Africa/Cairo')->withoutOverlapping()->runInBackground()
        ->appendOutputTo(storage_path('logs/balance.log'));
    Schedule::command('sim:matrix --n=1000')->dailyAt('04:30')->timezone('Africa/Cairo')->withoutOverlapping()->runInBackground()
        ->appendOutputTo(storage_path('logs/balance.log'));
    // The economy [Sprint 23 B5]: a season of club money, a few seconds.
    Schedule::command('sim:economy --report='.storage_path('app/balance/economy.json'))->dailyAt('05:00')->timezone('Africa/Cairo')->withoutOverlapping()->runInBackground();
}
