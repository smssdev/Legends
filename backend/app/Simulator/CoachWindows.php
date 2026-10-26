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
    /** [UP17] The sides whose injured player waits for his replacement (the emergency substitution). */
    public static function injured(array $state): array
    {
        return array_values(array_filter(['home', 'away'], fn ($side) => isset($state['teams'][$side]['pending_injury'])));
    }

    /**
     * The break after this minute (ms): half-time, extra time's, a coach's window, or [UP17] an emergency
     * substitution (the state given: only for the sides in $coaches, a computer's pick needs no wait).
     */
    public static function pauseMs(array $tick, array $timing, ?array $state = null, array $coaches = ['home', 'away']): int
    {
        if ($state !== null && ! empty($timing['emergency_sub']) && array_intersect(self::injured($state), $coaches)) {
            $emergency = (int) $timing['emergency_sub_seconds'] * 1000;
        }
        foreach ($tick['events'] ?? [] as $e) {
            if ($e['type'] === 'period' && $e['name'] === 'halftime') {
                return $timing['halftime_seconds'] * 1000;
            }
            if ($e['type'] === 'period' && in_array($e['name'], ['extra_time', 'extra_time_half', 'penalties'], true)) {
                return ($timing['extra_time_break_seconds'] ?? 10) * 1000;
            }
        }

        return max($emergency ?? 0, self::window($tick, $timing) ? (int) $timing['window_seconds'] * 1000 : 0);
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

    /**
     * [UP17] In an emergency stop that is not also a window: this side may only bring someone on for its injured
     * player. Returns the injured player's id, or null.
     */
    public static function emergencyFor(array $state, string $side): ?int
    {
        if (! isset($state['out']) || $state['finished'] || self::open($state)) {
            return null;
        }
        $id = $state['teams'][$side]['pending_injury'] ?? null;

        return $id === null ? null : (int) $id;
    }
}
