<?php

namespace App\Support;

use Illuminate\Support\Carbon;

/**
 * The game's clock [PLAN 1, GameClock]. Game logic asks this, never now(),
 * so tests (Carbon::setTestNow) and, later, clock:travel can move time.
 */
class GameClock
{
    public static function now(): Carbon
    {
        return Carbon::now();
    }

    public static function nowMs(): int
    {
        return (int) self::now()->getTimestampMs();
    }
}
