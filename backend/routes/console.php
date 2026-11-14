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
// A season whose last match is in: titles, objectives, then the new season or the end [Sprint 33].
Schedule::command('seasons:close')->everyMinute()->withoutOverlapping();
// The stadium's parts, coach online or not [Sprint 29].
Schedule::command('stadium:due')->everyMinute()->withoutOverlapping();
// Staff whose contract ended unrenewed resign [X20].
Schedule::command('staff:due')->everyMinute()->withoutOverlapping();
// A slot that opened with the account's age is announced in the inbox [Sprint 24 B3].
Schedule::command('slots:announce')->everyFiveMinutes()->withoutOverlapping();

// The scheduler's own sign of life for the health check (the watchdog runs that check apart) [Sprint 21 B2].
Schedule::call(fn () => ServerHealth::beat('scheduler'))->everyMinute()->name('heartbeat');

// [Sprint 21 E8.7] The logs never fill the disk: each over game.logs.max_mb is rotated.
Schedule::command('logs:trim')->hourly()->withoutOverlapping();
// [X65] The chat groups' messages older than the admin's retention (none while it is 0).
Schedule::command('chat:prune')->hourly()->withoutOverlapping();
// [Sprint 67] The coaches' table of the week to the game's public Telegram channel (Friday evening, Cairo).
Schedule::command('messenger:weekly')->weeklyOn(5, '20:13')->timezone('Africa/Cairo')->withoutOverlapping();
// [Sprint 66 B1] The devices' errors not seen for 30 days.
Schedule::command('client-errors:prune')->dailyAt('04:23')->timezone('Africa/Cairo')->withoutOverlapping();
// [Sprint 43 C6] A replay lasts its round: the scenes of the rounds before go, their results stay.
Schedule::command('matches:prune-replays')->hourly()->withoutOverlapping();

// Daily backup of the three SQLite files at 04:00 Cairo time, the quietest hour.
Schedule::command('db:backup')->dailyAt('04:00')->timezone('Africa/Cairo');
// [UP13] The accounts unused for 12 days are warned, for 14 deleted.
Schedule::command('accounts:inactive')->dailyAt('12:07')->timezone('Africa/Cairo')->withoutOverlapping();
// [Sprint 50 M5] The guests never kept, deleted after game.account.guest_days.
Schedule::command('guests:prune')->dailyAt('12:17')->timezone('Africa/Cairo')->withoutOverlapping();

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
