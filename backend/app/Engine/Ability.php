<?php

namespace App\Engine;

/**
 * Player and line ability per phase (docs/ENGINE.md 3). Ability is in
 * hundredths of a rating point: 60% of overall plus 40% of the attribute mix
 * for the phase, then fitness and position factors. Integers only.
 */
final class Ability
{
    /** Attribute weights per phase (sum 100). */
    public const MIX = [
        'build' => ['pas' => 50, 'dri' => 30, 'phy' => 20],
        'press' => ['phy' => 40, 'pac' => 30, 'def' => 30],
        'counter' => ['pac' => 60, 'dri' => 20, 'pas' => 20],
        'long' => ['pas' => 40, 'phy' => 60],
        'passing' => ['pas' => 60, 'dri' => 40],
        'wings' => ['pac' => 40, 'cross' => 40, 'dri' => 20],
        'shots' => ['pas' => 50, 'dri' => 50],
        'hold' => ['def' => 50, 'pac' => 30, 'phy' => 20],
        'hold_counter' => ['pac' => 50, 'def' => 40, 'phy' => 10],
        'create' => ['dri' => 40, 'pas' => 40, 'pac' => 20],
        'mark' => ['def' => 60, 'phy' => 40],
        'shoot' => ['sho' => 70, 'dri' => 30],
        'head' => ['head' => 70, 'phy' => 30],
        'keep' => ['gk' => 100],
    ];

    /** Which lines take part in each phase, and how much. */
    public const LINES = [
        'build' => ['def' => 1, 'mid' => 2],
        'press' => ['att' => 2, 'mid' => 1],
        'counter' => ['att' => 2, 'mid' => 1],
        'long' => ['def' => 1, 'att' => 2],
        'passing' => ['mid' => 3, 'att' => 1],
        'wings' => ['def' => 1, 'mid' => 1, 'att' => 1],
        'shots' => ['mid' => 2, 'att' => 1],
        'hold' => ['def' => 2, 'mid' => 1],
        'hold_counter' => ['def' => 3, 'mid' => 1],
        'create' => ['att' => 2, 'mid' => 1],
        'mark' => ['def' => 3, 'mid' => 1],
    ];

    public static function player(array $p, string $mix): int
    {
        $a = $p['a'];
        $sum = 0;
        foreach (self::MIX[$mix] as $attr => $weight) {
            $sum += ($a[$attr] ?? 40) * $weight;
        }
        $base = 60 * $a['ovr'] + 40 * intdiv($sum, 100);

        return intdiv(intdiv($base * self::fitness($p['fit']), 10000) * self::position($p), 10000);
    }

    /** Average ability of the lines taking part in a phase, weighted by line. */
    public static function lines(array $team, string $mix, array $weights): int
    {
        $total = 0;
        $weight = 0;
        foreach ($team['players'] as $p) {
            if (! $p['on'] || $p['line'] === 'gk') {
                continue;
            }
            $w = $weights[$p['slot_line']] ?? 0;
            if ($w > 0) {
                $total += self::player($p, $mix) * $w;
                $weight += $w;
            }
        }

        return $weight > 0 ? intdiv($total, $weight) : 3000;
    }

    /**
     * Fitness effect in basis points [Sprint 39 E2, the owner's simulation file]: full from 90%; from 80% to 90% five to
     * ten per cent less; from 75% to 80% up to fifteen; under 75% a sharp drop, down to a quarter less at 50% and under.
     */
    public static function fitness(int $fit): int
    {
        return match (true) {
            $fit >= 9000 => 10000,
            $fit >= 8000 => 9000 + intdiv(($fit - 8000) * 500, 1000),
            $fit >= 7500 => 8500 + intdiv(($fit - 7500) * 500, 500),
            default => 7500 + intdiv(max(0, $fit - 5000) * 1000, 2500),
        };
    }

    /**
     * Out-of-position penalty [Sprint 39 E1, the owner's simulation file]: none in the player's line; 30% off one line
     * away (a defender in midfield, a midfielder up front), 50% off two lines away (a defender up front); a keeper out
     * of goal, or an outfield player in it, 60% off.
     */
    public static function position(array $p): int
    {
        $native = $p['line'];
        $slot = $p['slot_line'] ?? $native;
        if ($native === $slot || in_array($slot, self::alsoPlays($p), true)) {
            return 10000;
        }
        if ($native === 'gk' || $slot === 'gk') {
            return 4000;
        }
        $order = ['def' => 0, 'mid' => 1, 'att' => 2];

        return abs($order[$native] - $order[$slot]) === 1 ? 7000 : 5000;
    }

    /** The positions' lines (a winger on the wing of midfield and back is in his place, as the formations' slots say). */
    private const POSITION_LINES = ['GK' => ['gk'], 'CB' => ['def'], 'LB' => ['def'], 'RB' => ['def'], 'LWB' => ['def', 'mid'], 'RWB' => ['def', 'mid'],
        'CDM' => ['mid'], 'CM' => ['mid'], 'CAM' => ['mid'], 'LM' => ['mid', 'att'], 'RM' => ['mid', 'att'], 'LW' => ['att', 'mid'], 'RW' => ['att', 'mid'],
        'ST' => ['att'], 'CF' => ['att']];

    /** @return list<string> the other lines a player's position and his second positions belong to */
    private static function alsoPlays(array $p): array
    {
        $lines = [];
        foreach (array_merge([$p['pos'] ?? ''], explode(',', (string) ($p['alt'] ?? ''))) as $pos) {
            $lines = array_merge($lines, self::POSITION_LINES[trim($pos)] ?? []);
        }

        return $lines;
    }
}
