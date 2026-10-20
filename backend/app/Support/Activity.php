<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

/**
 * One row per user per day [PLAN 2.22]: sign-ins, matches watched live and orders sent.
 * The admin board shows who keeps coming back.
 */
class Activity
{
    public const COUNTERS = ['logins', 'matches_watched', 'orders'];

    public static function record(int $userId, string $counter): void
    {
        if (! in_array($counter, self::COUNTERS, true)) {
            throw new \InvalidArgumentException($counter);
        }
        $day = GameClock::now()->timezone('Africa/Cairo')->toDateString();
        DB::table('user_activity')->insertOrIgnore(['user_id' => $userId, 'day' => $day]);
        DB::table('user_activity')->where(['user_id' => $userId, 'day' => $day])->increment($counter);
    }
}
