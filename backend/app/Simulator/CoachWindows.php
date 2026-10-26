<?php

namespace App\Simulator;

/**
 * The coach's windows [X42], the owner's (2026-10-26): play stops for a breath every 15 minutes (game.match.windows,
 * minutes 15, 30, 60 and 75), as at half-time, and only then (and before kick-off, at half-time, in extra time's
 * breaks) may a coach change his line-up, his tactics or make a substitution. Between them the match plays on: an
 * injured player is replaced by the engine at once, as before. The same rule for every side: the assistant of an
 * absent coach, the computer and the coach's own scenarios act in the windows too.
 *
 * A match made before has no windows in its config_snapshot: its coaches change at any minute, as they did.
 */
class CoachWindows
{
    /** The break after this minute (ms): half-time, extra time's, or a coach's window. */
    public static function pauseMs(array $tick, array $timing): int
    {
        foreach ($tick['events'] ?? [] as $e) {
            if ($e['type'] === 'period' && $e['name'] === 'halftime') {
                return $timing['halftime_seconds'] * 1000;
            }
            if ($e['type'] === 'period' && in_array($e['name'], ['extra_time', 'extra_time_half', 'penalties'], true)) {
                return ($timing['extra_time_break_seconds'] ?? 10) * 1000;
            }
        }

        return self::window($tick, $timing) ? (int) $timing['window_seconds'] * 1000 : 0;
    }

    /** The minute stops for a window: 15, 30, 60 or 75 of normal time, not a minute added on. */
    public static function window(array $tick, array $timing): bool
    {
        $minute = $tick['minute'] ?? null;
        if (empty($timing['windows']) || ! is_array($minute) || (int) $minute[1] !== 0 || (int) ($tick['period'] ?? 1) > 2) {
            return false;
        }

        return in_array((int) $minute[0], $timing['windows'], true);
    }

    /** The match has windows (made from X42 on). */
    public static function used(array $state): bool
    {
        return ! empty($state['cfg']['match']['windows']);
    }

    /**
     * May a coach change now: before kick-off, or the last minute made stops for a break (its order goes into the
     * first minute after it). Always, in a match without windows.
     */
    public static function open(array $state): bool
    {
        if (! self::used($state) || ! isset($state['out'])) {
            return true;
        }

        return ! $state['finished'] && self::pauseMs($state['out'], $state['cfg']['match']) > 0;
    }
}
