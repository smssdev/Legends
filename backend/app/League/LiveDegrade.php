<?php

namespace App\League;

use Illuminate\Support\Facades\Cache;

/**
 * The live broadcast's degradation ladder [Sprint 21 E8.7]: when the server is short of breath, the live matches
 * give up their extras in this order, never the match itself (the minutes, the score and the orders always go on):
 *
 *   0  everything (normal).
 *   1  no summary: a screen back after a gap jumps to now without the summary and the missed minutes' events.
 *   2  and no voice: the commentator's line leaves the minute (the written events stay).
 *   3  and less often: the screens are told to poll every poll_ms (config) instead of about once a second.
 *
 * The level is game.live.degrade.level (env GAME_DEGRADE_LEVEL), or what `matches:degrade` set for now.
 */
class LiveDegrade
{
    public const MAX = 3;

    public static function level(): int
    {
        $set = Cache::get('live-degrade');

        return max(0, min(self::MAX, (int) ($set ?? config('game.live.degrade.level'))));
    }

    /** Set the level for the next hours (null goes back to the config's). */
    public static function set(?int $level, int $hours = 6): void
    {
        $level === null ? Cache::forget('live-degrade') : Cache::put('live-degrade', max(0, min(self::MAX, $level)), $hours * 3600);
    }

    public static function summary(): bool
    {
        return self::level() < 1;
    }

    public static function voice(): bool
    {
        return self::level() < 2;
    }

    /** How long the screens wait between two polls, or null for their own pace. */
    public static function pollMs(): ?int
    {
        return self::level() >= 3 ? (int) config('game.live.degrade.poll_ms') : null;
    }
}
