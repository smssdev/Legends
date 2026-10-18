<?php

use Illuminate\Support\Facades\Schedule;

// The scheduler runs every minute on the server (Windows Task Scheduler or cron).
// Daily backup of the three SQLite files at 04:00 Cairo time, the quietest hour.
Schedule::command('db:backup')->dailyAt('04:00')->timezone('Africa/Cairo');
