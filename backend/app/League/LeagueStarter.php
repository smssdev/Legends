<?php

namespace App\League;

use App\Models\League;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * A league starts at the owner's time [PLAN 2.1]: its first season begins (the preparation days
 * first) and every setting, the name too, is locked for good [PLAN 2.3].
 */
class LeagueStarter
{
    /** Start the leagues whose time has come. Returns how many started. */
    public static function due(): int
    {
        $started = 0;
        League::where('status', 'waiting')->where('starts_at', '<=', GameClock::now())->orderBy('id')
            ->each(function (League $league) use (&$started) {
                $started += self::start($league) ? 1 : 0;
            });

        return $started;
    }

    /** Start one league now (the scheduler, or "start now" in development). False when it had already started. */
    public static function start(League $league): bool
    {
        // A draw set for the start or still waiting is made first [X26].
        if ($league->draw_at && ! $league->drawn_at) {
            LiveDraw::draw($league);
            $league = $league->fresh();
        }

        return DB::transaction(function () use ($league) {
            $now = GameClock::now();
            // "Start now" moves an early start to this minute; the scheduler starts on time anyway.
            $starts = $league->starts_at->lt($now) ? $league->starts_at : $now;
            $changed = DB::table('leagues')->where('id', $league->id)->where('status', 'waiting')
                ->update(['status' => 'running', 'settings_locked_at' => $now, 'starts_at' => $starts, 'updated_at' => $now]);
            if ($changed !== 1) {
                return false;
            }
            DB::table('seasons')->where('league_id', $league->id)->where('number', 1)
                ->update(['status' => 'running', 'starts_at' => $starts, 'updated_at' => $now]);
            // Started early ("start now"): the calendar moves with it.
            if ($starts->ne($league->starts_at)) {
                $fresh = $league->fresh();
                SeasonScheduler::build($fresh, $fresh->season);
            }

            return true;
        });
    }
}
