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
        $m = self::shot($events, $match, $period);
        // [Sprint 40 A1] How a card or a foul is told (drama): decided here so every screen and the replay tell it alike.
        $drama = self::drama($m['kind'], $events);

        return $drama ? $m + ['drama' => $drama] : $m;
    }

    private static function shot(array $events, array $match, int $period): array
    {
        // [Sprint 40 A2] A foul gets its own scene only in a match made with its length (config_snapshot).
        $kind = self::kind($events, isset($match['broadcast_ms']['foul']));
        // [X41] The broadcast as on TV, the owner's (2026-10-26): fewer scenes, each as long as it really takes. The big
        // moments (a goal, a penalty, a card, a real chance) play in full with time for the commentator and, after a goal,
        // a replay; a small one (a blocked or a weak shot, an offside, a free kick wide) is only its card and one line.
        if (isset($match['broadcast_ms'])) {
            $table = $match['broadcast_ms'];
            if ($kind === 'shootout') {
                return ['kind' => $kind, 'ms' => (int) $match['shootout_ms']];
            }
            // [X94] And the kinds the highlights broadcast always tells as a card (broadcast_brief).
            if (self::brief($kind, $events) || (in_array($kind, $match['broadcast_brief'] ?? [], true) && ! self::scored($events))) {
                return ['kind' => $kind, 'ms' => (int) $table['brief'], 'brief' => true];
            }
            $key = in_array($kind, ['free_kick', 'penalty'], true) && self::scored($events) ? $kind.'_goal' : $kind;
            $ms = (int) ($table[$key] ?? $table[$kind]);
            if ($kind === 'var') {
                return ['kind' => $kind, 'ms' => $ms, 'var' => self::varReason($events)];
            }
            // Extra time runs faster: its half is a quarter of an hour.
            if ($period >= 3 && in_array($kind, ['quiet', 'attack'], true)) {
                $ms = intdiv($ms * 2, 3);
            }

            return ['kind' => $kind, 'ms' => $ms];
        }
        // [X35] The broadcast's fixed pace: every minute as long as the next, so the clock on screen runs like TV's.
        if (isset($match['minute_ms'])) {
            $ms = $kind === 'shootout' ? $match['shootout_ms'] : ($period >= 3 ? $match['extra_minute_ms'] : $match['minute_ms']);

            return ['kind' => $kind, 'ms' => (int) $ms] + ($kind === 'var' ? ['var' => self::varReason($events)] : []);
        }
        $table = $match['moment_ms'] ?? null;
        if ($table === null) {
            return ['kind' => $kind, 'ms' => (int) $match['tick_ms']];
        }
        $key = in_array($kind, ['free_kick', 'penalty'], true) && self::scored($events) ? $kind.'_goal' : $kind;
        // A breath after every scene: the timeline and the clock before the next one.
        $gap = in_array($kind, ['quiet', 'attack'], true) ? 0 : (int) ($match['scene_gap_ms'] ?? 0);

        return ['kind' => $kind, 'ms' => (int) ($table[$key] ?? $table[$kind] ?? $table['offside']) + $gap] + ($kind === 'var' ? ['var' => self::varReason($events)] : []);
    }

    /**
     * [Sprint 35 C3] Why a minute is told as a goal ruled out by VAR: 'offside' for one offside in three (the ball over
     * the top went in, and the check finds the runner ahead; which ones from the attack's own players and lane, so the
     * same everywhere), 'foul' when the attacking side fouled in the same minute of a chance that came to nothing, or
     * null. From the events only, so every screen and the replay tell the same.
     */
    public static function varReason(array $events): ?string
    {
        $attack = self::first($events, 'attack');
        if (! $attack) {
            return null;
        }
        if (($attack['result'] ?? '') === 'offside') {
            $key = implode(':', [$attack['team'] ?? '', $attack['carrier'] ?? '', $attack['receiver'] ?? '', $attack['lane'] ?? '']);

            return crc32('var:'.$key) % 3 === 0 ? 'offside' : null;
        }
        if (in_array($attack['result'] ?? '', ['missed', 'blocked', 'saved'], true)) {
            foreach ($events as $e) {
                if ($e['type'] === 'foul' && ($e['team'] ?? null) === $attack['team'] && ! ($e['penalty'] ?? false)) {
                    return 'foul';
                }
            }
        }

        return null;
    }

    /** [X41] A moment too small for its own scene on the broadcast: its card and one line only. */
    public static function brief(string $kind, array $events): bool
    {
        $attack = self::first($events, 'attack');

        return match ($kind) {
            'offside' => true,
            'miss' => ($attack['result'] ?? '') === 'blocked' || ! in_array($attack['quality'] ?? '', ['big', 'header'], true),
            'save' => ! in_array($attack['quality'] ?? '', ['big', 'header'], true),
            'free_kick' => ! self::scored($events) && ! (self::first($events, 'free_kick')['keeper'] ?? null),
            default => false,
        };
    }

    /**
     * [Sprint 40 A1] The cartoon's telling of a card or a foul, from the events only (the same on every screen):
     * yellow: 'tackle' or 'swarm' (his team-mates surround the referee); red: 'tackle', 'brawl' (a fight in a cloud of
     * dust) or 'spit' (he argues, then spits at the referee); foul: 'tackle' or 'dive' (he goes down untouched and the
     * referee gives it). Drawing only: the engine's card and foul stay what they are.
     */
    public static function drama(string $kind, array $events): ?string
    {
        if (in_array($kind, ['yellow', 'red'], true)) {
            $card = self::first($events, 'card');
            $foul = self::first($events, 'foul');
            $n = crc32('drama:'.($card['player'] ?? '').':'.($foul['victim'] ?? '')) % 12;
            if ($kind === 'yellow') {
                return $n < 4 ? 'swarm' : 'tackle';
            }

            return ($card['second_yellow'] ?? false) ? ($n < 6 ? 'swarm' : 'tackle') : ($n < 3 ? 'spit' : ($n < 7 ? 'brawl' : 'tackle'));
        }
        if ($kind === 'foul') {
            $foul = self::foul($events);

            return crc32('dive:'.($foul['player'] ?? '').':'.($foul['victim'] ?? '')) % 2 === 0 ? 'dive' : 'tackle';
        }

        return null;
    }

    /** [Sprint 40 A2] The foul (not a penalty) the minute shows as its scene: one in three, chosen by its players. */
    private static function foul(array $events): ?array
    {
        foreach ($events as $e) {
            if ($e['type'] === 'foul' && ! ($e['penalty'] ?? false) && isset($e['player'], $e['victim'])) {
                return crc32('foul:'.$e['player'].':'.$e['victim']) % 3 === 0 ? $e : null;
            }
        }

        return null;
    }

    public static function kind(array $events, bool $fouls = false): string
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
        // [Sprint 35 C3] A goal ruled out after a look at VAR: a big chance that ended offside, or one the attacking
        // side fouled in. Told as the ball in the net, the check, and no goal; the result is the engine's all the same.
        if (self::varReason($events)) {
            return 'var';
        }
        if ($attack) {
            $kind = match ($attack['result']) {
                'saved', 'corner' => 'save', 'missed', 'blocked' => 'miss', 'offside' => 'offside', default => null,
            };
            if ($kind) {
                return $kind;
            }
        }
        if ($fouls && self::foul($events)) {
            return 'foul';
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
