<?php

use Illuminate\Support\Facades\Schedule;

// The scheduler runs every minute on the server (Windows Task Scheduler or cron).
// Leagues start at the time their owner chose [PLAN 2.1].
Schedule::command('leagues:start')->everyMinute()->withoutOverlapping();

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
}
