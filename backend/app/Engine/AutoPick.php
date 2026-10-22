<?php

namespace App\Engine;

/**
 * The "تحسين" service (Sprint 1 B3): best eleven, formation, bench and
 * set-piece takers for a squad. Pure: works on player arrays, no database.
 */
final class AutoPick
{
    public const BENCH = 7;

    /** Most real teams play four at the back: a small tie-break in their favour. */
    private const PREFERENCE = ['4-2-3-1' => 600, '4-3-3' => 500, '4-4-2' => 400, '4-1-4-1' => 400, '3-5-2' => 0, '5-3-2' => 0];

    /**
     * @param  list<array>  $squad  players with id, pos, alt, line, a.ovr and attributes
     * @return array{formation: string, starters: list<int>, bench: list<int>}
     */
    public static function pick(array $squad, ?string $formation = null): array
    {
        $available = array_values(array_filter($squad, fn ($p) => empty($p['unavailable'])));
        $best = null;

        foreach ($formation ? [$formation] : Formations::names() as $name) {
            [$score, $starters] = self::fill($available, Formations::slots($name));
            $score += self::PREFERENCE[$name] ?? 0;
            if ($best === null || $score > $best[0] || ($score === $best[0] && $name === Formations::DEFAULT)) {
                $best = [$score, $starters, $name];
            }
        }

        [, $starters, $name] = $best;
        $chosen = array_flip($starters);
        $rest = array_values(array_filter($available, fn ($p) => ! isset($chosen[$p['id']])));
        usort($rest, fn ($a, $b) => $b['a']['ovr'] <=> $a['a']['ovr'] ?: $a['id'] <=> $b['id']);

        // One goalkeeper on the bench first, then the strongest of the rest.
        $bench = [];
        foreach ($rest as $p) {
            if ($p['line'] === 'gk') {
                $bench[] = $p['id'];
                break;
            }
        }
        foreach ($rest as $p) {
            if (count($bench) >= self::BENCH) {
                break;
            }
            if (! in_array($p['id'], $bench, true)) {
                $bench[] = $p['id'];
            }
        }

        return ['formation' => $name, 'starters' => $starters, 'bench' => $bench];
    }

    /**
     * Global greedy matching: the best (player, slot) pairs are taken first, so
     * a star winger is not pushed into a centre-back slot just because that
     * slot happens to be filled earlier.
     */
    private static function fill(array $players, array $slots): array
    {
        $pairs = [];
        foreach ($slots as $i => $slot) {
            foreach ($players as $p) {
                $pairs[] = [$p['a']['ovr'] * 100 - self::misfit($p, $slot), $i, $p['id']];
            }
        }
        usort($pairs, fn ($a, $b) => $b[0] <=> $a[0] ?: $a[1] <=> $b[1] ?: $a[2] <=> $b[2]);

        $starters = [];
        $used = [];
        $score = 0;
        foreach ($pairs as [$value, $slot, $id]) {
            if (isset($starters[$slot]) || isset($used[$id])) {
                continue;
            }
            $starters[$slot] = $id;
            $used[$id] = true;
            $score += $value;
        }
        ksort($starters);

        return [$score, array_values($starters)];
    }

    /** Penalty (hundredths of a point) for a player in a slot. */
    public static function misfit(array $p, array $slot): int
    {
        // A league formation's slot (App\League\FormationBook) names its role only.
        $fits = $slot['fits'] ?? [$slot['role']];
        if (in_array($p['pos'], $fits, true)) {
            return 0;
        }
        if ($slot['line'] === 'gk' || $p['line'] === 'gk') {
            return 6000;
        }
        $alt = array_map('trim', explode(',', (string) ($p['alt'] ?? '')));
        if (array_intersect($alt, $fits)) {
            return 200;
        }

        return $p['line'] === $slot['line'] ? 500 : 1200;
    }

    /** Captain and set-piece takers among the starters (docs/PLAN.md 2.16). */
    public static function takers(array $players): array
    {
        $on = array_values(array_filter($players, fn ($p) => $p['on']));
        $field = array_values(array_filter($on, fn ($p) => $p['line'] !== 'gk')) ?: $on;
        $best = function (array $list, callable $key) {
            usort($list, fn ($a, $b) => $key($b) <=> $key($a) ?: $a['id'] <=> $b['id']);

            return $list[0]['id'] ?? null;
        };
        $top = $on;
        usort($top, fn ($a, $b) => $b['a']['ovr'] <=> $a['a']['ovr'] ?: $a['id'] <=> $b['id']);

        return [
            'captain' => $best(array_slice($top, 0, 5), fn ($p) => $p['age'] * 100 + $p['a']['ovr']),
            'penalty' => $best($field, fn ($p) => $p['a']['pen'] ?? 0),
            'free_kick' => $best($field, fn ($p) => $p['a']['fk'] ?? 0),
            'corner' => $best($field, fn ($p) => $p['a']['cross'] ?? 0),
        ];
    }
}
