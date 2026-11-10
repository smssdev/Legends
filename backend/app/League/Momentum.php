<?php

namespace App\League;

/**
 * [Sprint 50 M15] The live momentum wave: the engine already keeps, minute by minute, which side was dangerous and how
 * much (state.momentum: +2 a home chance, +1 a home attack, the same below zero for the away side, 0 a quiet minute).
 * The screens draw the wave from the minute's value and show the share of the last `window` minutes.
 * Integers only, like everything the match gives.
 */
class Momentum
{
    /** ['now' => this minute's value, 'home_pct' => the home side's share (0..100) of the last minutes' danger]. */
    public static function wave(array $momentum, int $window = 10): array
    {
        $last = array_slice($momentum, -$window);
        $home = array_sum(array_filter($last, fn ($v) => $v > 0));
        $away = -array_sum(array_filter($last, fn ($v) => $v < 0));

        return ['now' => (int) (end($momentum) ?: 0), 'home_pct' => $home + $away === 0 ? 50 : intdiv(100 * $home, $home + $away)];
    }
}
