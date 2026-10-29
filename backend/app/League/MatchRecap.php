<?php

namespace App\League;

/**
 * The quick recap of a finished league match [Sprint 24 B1, the owner's request 2026-10-29]: for the coach who
 * missed it live, its big moments in order (the goals, the cards, the substitutions, the injuries and the
 * penalties), each with the score after it, then the final score, the main numbers and the best ratings of each
 * side. Built from the coach's own stored report alone, so it shows nothing the report does not (no tactics).
 * The screen plays the moments fast, one after another, and can skip straight to the end.
 */
class MatchRecap
{
    public const MOMENTS = ['goal', 'card', 'sub', 'injury', 'penalty'];

    /** The stats shown at the end, each side's. */
    public const STATS = ['shots', 'on_target', 'big_chances', 'corners', 'fouls', 'yellow', 'red', 'saves'];

    public static function build(array $report): array
    {
        $names = [];
        foreach (['home', 'away'] as $side) {
            foreach ($report['ratings'][$side] ?? [] as $p) {
                $names[(int) $p['id']] = $p['name'];
            }
        }
        $name = fn ($id) => $id ? ($names[(int) $id] ?? null) : null;
        $score = ['home' => 0, 'away' => 0];
        $moments = [];
        foreach ($report['timeline'] ?? [] as $e) {
            if (! in_array($e['type'], self::MOMENTS, true)) {
                continue;
            }
            if ($e['type'] === 'goal') {
                $score = isset($e['score']) ? ['home' => (int) $e['score']['home'], 'away' => (int) $e['score']['away']]
                    : [...$score, $e['team'] => $score[$e['team']] + 1];
            }
            $moments[] = ['minute' => is_array($e['minute']) ? array_sum($e['minute']) : (int) $e['minute'], 'type' => $e['type'], 'team' => $e['team'] ?? null,
                'player' => $name($e['scorer'] ?? $e['player'] ?? $e['taker'] ?? $e['out'] ?? null),
                // The second name: the assist of a goal, or who came on for a substitution.
                'other' => $name($e['type'] === 'goal' ? ($e['assist'] ?? null) : ($e['type'] === 'sub' ? ($e['in'] ?? null) : null)),
                'color' => $e['type'] === 'card' ? ($e['color'] ?? 'yellow') : null,
                'score' => $score];
        }

        return [
            'side' => $report['side'] ?? null,
            'result' => $report['result'],
            'score' => ['home' => (int) $report['score']['home'], 'away' => (int) $report['score']['away']],
            'shootout' => $report['shootout'] ?? null,
            'moments' => $moments,
            'stats' => self::stats($report['stats'] ?? []),
            'best' => array_map(fn ($side) => array_map(fn ($p) => ['id' => (int) $p['id'], 'name' => $p['name'], 'rating' => (int) $p['rating']],
                array_slice($report['ratings'][$side] ?? [], 0, 3)), ['home' => 'home', 'away' => 'away']),
            'man_of_the_match' => $report['man_of_the_match'] ?? null,
        ];
    }

    /** Possession as each side's share of the attacks (the two make 100), and the other numbers as they are. */
    private static function stats(array $stats): array
    {
        $home = (int) ($stats['home']['attacks'] ?? 0);
        $all = $home + (int) ($stats['away']['attacks'] ?? 0);
        $possession = $all ? intdiv($home * 100 + intdiv($all, 2), $all) : 50;
        $out = [];
        foreach (['home' => $possession, 'away' => 100 - $possession] as $side => $share) {
            $out[$side] = ['possession' => $share];
            foreach (self::STATS as $key) {
                $out[$side][$key] = (int) ($stats[$side][$key] ?? 0);
            }
        }

        return $out;
    }
}
