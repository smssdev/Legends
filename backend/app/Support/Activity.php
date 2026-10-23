<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

/**
 * One row per user per day [PLAN 2.22]: sign-ins, visits (any signed-in request, Sprint 37), matches watched
 * live and orders sent. The admin board shows who keeps coming back (weeks()).
 */
class Activity
{
    public const COUNTERS = ['logins', 'visits', 'matches_watched', 'orders'];

    public static function record(int $userId, string $counter): void
    {
        if (! in_array($counter, self::COUNTERS, true)) {
            throw new \InvalidArgumentException($counter);
        }
        $day = GameClock::now()->timezone('Africa/Cairo')->toDateString();
        DB::table('user_activity')->insertOrIgnore(['user_id' => $userId, 'day' => $day]);
        DB::table('user_activity')->where(['user_id' => $userId, 'day' => $day])->increment($counter);
    }

    /**
     * The last weeks, newest first: accounts active, of them how many were active the week before too (the return
     * indicator: friends come back week after week), and how many watched a match live.
     *
     * @return list<array{week: string, active: int, returning: int, live: int}>
     */
    public static function weeks(int $count = 8): array
    {
        $today = GameClock::now()->timezone('Africa/Cairo')->startOfDay();
        $out = [];
        $previous = null;
        for ($w = $count; $w >= 0; $w--) {
            $from = $today->copy()->subDays(7 * $w + 6)->toDateString();
            $to = $today->copy()->subDays(7 * $w)->toDateString();
            $users = DB::table('user_activity')->whereBetween('day', [$from, $to])->distinct()->pluck('user_id')->all();
            $live = (int) DB::table('user_activity')->whereBetween('day', [$from, $to])->where('matches_watched', '>', 0)->distinct()->count('user_id');
            if ($previous !== null) {
                $out[] = ['week' => $to, 'active' => count($users), 'returning' => count(array_intersect($users, $previous)), 'live' => $live];
            }
            $previous = $users;
        }

        return array_reverse($out);
    }
}
