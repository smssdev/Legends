<?php

namespace App\League;

/**
 * What one coach may know of a match [ENGINE 8.1, 8.2, Sprint 20 B2]: the input of the live readings and the
 * report, as a type of its own. It is built from an allowlist: the score, the public counts of both sides
 * (attacks, chances, cards: what anyone watching sees happen), the players' names, numbers, fitness and
 * ratings, and the formations. Tactics are left out for both sides (the report speaks of the coach's own
 * through his own sheet, never of the other's), so the other side's hidden values (pressing, style, tempo,
 * positioning, the defensive shape) cannot reach a reading or a report: they are not here to read.
 */
final class MatchFacts
{
    private const PLAYER = ['id', 'name', 'no', 'pos', 'line', 'slot_line', 'on', 'out', 'fit', 'yc'];

    private const PLAYER_STATS = ['shots', 'goals', 'assists', 'r'];

    public static function of(array $state, string $side): array
    {
        $other = $side === 'home' ? 'away' : 'home';

        return [
            'side' => $side,
            'tick' => (int) ($state['tick'] ?? 0),
            'minute' => self::minute($state),
            'score' => $state['score'],
            'shootout' => $state['shootout'] ?? null,
            'thirds' => $state['thirds'] ?? [0, 0, 0],
            'momentum' => $state['momentum'] ?? [],
            'teams' => [$side => self::team($state['teams'][$side]), $other => self::team($state['teams'][$other])],
        ];
    }

    private static function team(array $t): array
    {
        return [
            'club' => ['id' => $t['club']['id'], 'name' => $t['club']['name'], 'code' => $t['club']['code']],
            'formation' => $t['formation'],
            'subs_used' => $t['subs_used'],
            'subs_max' => $t['subs_max'],
            'stats' => $t['stats'],
            'players' => array_map(fn ($p) => array_intersect_key($p, array_flip(self::PLAYER))
                + ['st' => array_intersect_key($p['st'], array_flip(self::PLAYER_STATS))], $t['players']),
        ];
    }

    private static function minute(array $state): int
    {
        $m = $state['out']['minute'] ?? [0, 0];

        return is_array($m) ? $m[0] + $m[1] : (int) $m;
    }
}
