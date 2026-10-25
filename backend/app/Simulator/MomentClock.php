<?php

namespace App\Simulator;

/**
 * Which shot a minute gets on screen and how long it plays (docs/MOMENTS.md).
 * Decided on the server so both screens of a live match stay in step and a
 * replay lasts exactly as long as the original. Pure: events and config in.
 */
class MomentClock
{
    public static function moment(array $events, array $match, int $period = 1): array
    {
        $kind = self::kind($events);
        // [X35] The broadcast's fixed pace: every minute as long as the next, so the clock on screen runs like TV's.
        if (isset($match['minute_ms'])) {
            $ms = $kind === 'shootout' ? $match['shootout_ms'] : ($period >= 3 ? $match['extra_minute_ms'] : $match['minute_ms']);

            return ['kind' => $kind, 'ms' => (int) $ms];
        }
        $table = $match['moment_ms'] ?? null;
        if ($table === null) {
            return ['kind' => $kind, 'ms' => (int) $match['tick_ms']];
        }
        $key = in_array($kind, ['free_kick', 'penalty'], true) && self::scored($events) ? $kind.'_goal' : $kind;
        // A breath after every scene: the timeline and the clock before the next one.
        $gap = in_array($kind, ['quiet', 'attack'], true) ? 0 : (int) ($match['scene_gap_ms'] ?? 0);

        return ['kind' => $kind, 'ms' => (int) ($table[$key] ?? $table[$kind]) + $gap];
    }

    public static function kind(array $events): string
    {
        $types = array_column($events, 'type');
        $goal = self::first($events, 'goal');
        if ($goal) {
            return match ($goal['kind'] ?? 'open') {
                'penalty' => 'penalty', 'free_kick' => 'free_kick', default => 'goal'
            };
        }
        foreach (['penalty', 'free_kick'] as $t) {
            if (in_array($t, $types, true)) {
                return $t;
            }
        }
        $card = self::first($events, 'card');
        if ($card) {
            return $card['color'] === 'red' ? 'red' : 'yellow';
        }
        $attack = self::first($events, 'attack');
        if ($attack) {
            $kind = match ($attack['result']) {
                'saved', 'corner' => 'save', 'missed', 'blocked' => 'miss', 'offside' => 'offside', default => null,
            };
            if ($kind) {
                return $kind;
            }
        }
        if (in_array('corner', $types, true)) {
            return 'corner';
        }
        if (in_array('injury', $types, true)) {
            return 'injury';
        }
        if (in_array('sub', $types, true)) {
            return 'sub';
        }
        if (self::coach($events)) {
            return 'coach';
        }
        if (in_array('shootout', $types, true)) {
            return 'shootout';
        }
        if (in_array('period', $types, true)) {
            return 'whistle';
        }
        if (in_array('stoppage', $types, true)) {
            return 'stoppage';
        }

        return $attack ? 'attack' : 'quiet';
    }

    // A coach changed the tactics or the shape this minute (a sub has its own shot).
    private static function coach(array $events): bool
    {
        foreach ($events as $e) {
            if ($e['type'] === 'action' && in_array($e['action']['type'] ?? '', ['tactics', 'formation'], true)) {
                return true;
            }
        }

        return false;
    }

    private static function scored(array $events): bool
    {
        return (bool) self::first($events, 'goal');
    }

    private static function first(array $events, string $type): ?array
    {
        foreach ($events as $e) {
            if ($e['type'] === $type) {
                return $e;
            }
        }

        return null;
    }
}
