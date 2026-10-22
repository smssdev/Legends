<?php

namespace App\Engine;

/**
 * Coach orders applied at the start of a minute (docs/PLAN.md 2.12): a
 * substitution, a tactics change or a new formation. Each is validated by
 * the engine's own rules; an invalid order changes nothing.
 */
final class Actions
{
    private const TACTIC_RULES = [
        'plan' => ['counter', 'long', 'passing', 'wings', 'shots'],
        'tackling' => [0, 3],
        'pressing' => [0, 100],
        'style' => [0, 100],
        'tempo' => [0, 100],
        'att' => ['back', 'support', 'only'],
        'mid' => ['def', 'stay', 'push'],
        'def' => ['stay', 'fullbacks', 'mid'],
        'trap' => [0, 1],
        'marking' => ['zone', 'man'],
    ];

    /** Applies an order to the state; returns an error code or null. */
    public static function apply(array &$s, array $action): ?string
    {
        $side = $action['team'] ?? null;
        if (! in_array($side, ['home', 'away'], true)) {
            return 'bad_team';
        }

        return match ($action['type'] ?? null) {
            'sub' => self::sub($s['teams'][$side], (int) ($action['out'] ?? 0), (int) ($action['in'] ?? 0)),
            'tactics' => self::tactics($s['teams'][$side], (array) ($action['tactics'] ?? [])),
            'formation' => self::formation($s['teams'][$side], (string) ($action['formation'] ?? ''), $action['slots'] ?? null),
            default => 'bad_type',
        };
    }

    public static function validTactics(array $changes): bool
    {
        foreach ($changes as $key => $value) {
            $rule = self::TACTIC_RULES[$key] ?? null;
            if ($rule === null) {
                return false;
            }
            if (is_int($rule[0]) && count($rule) === 2 && ! is_string($value)) {
                if (! is_int($value) || $value < $rule[0] || $value > $rule[1]) {
                    return false;
                }
            } elseif (! in_array($value, $rule, true)) {
                return false;
            }
        }

        return true;
    }

    private static function sub(array &$team, int $outId, int $inId): ?string
    {
        if ($team['subs_used'] >= $team['subs_max']) {
            return 'no_subs_left';
        }
        $out = $in = null;
        foreach ($team['players'] as $i => $p) {
            if ($p['id'] === $outId && $p['on']) {
                $out = $i;
            }
            if ($p['id'] === $inId && ! $p['on'] && $p['out'] === '' && $p['slot'] === null) {
                $in = $i;
            }
        }
        if ($out === null || $in === null) {
            return 'bad_players';
        }

        $team['players'][$in]['on'] = true;
        $team['players'][$in]['slot'] = $team['players'][$out]['slot'];
        $team['players'][$in]['slot_line'] = $team['players'][$out]['slot_line'];
        $team['players'][$out]['on'] = false;
        $team['players'][$out]['out'] = 'sub';
        $team['subs_used']++;
        $team['takers'] = AutoPick::takers($team['players']);

        return null;
    }

    private static function tactics(array &$team, array $changes): ?string
    {
        if (! $changes || ! self::validTactics($changes)) {
            return 'bad_tactics';
        }
        $team['tactics'] = array_merge($team['tactics'], $changes);

        return null;
    }

    /**
     * Re-slots the players on the pitch into a new formation, keeper in goal: one by name, or a league
     * side's own (its slots given with it, the goalkeeper first).
     */
    private static function formation(array &$team, string $name, mixed $own = null): ?string
    {
        if ($own !== null ? ! self::validSlots($own) : ! Formations::exists($name)) {
            return 'bad_formation';
        }
        $slots = $own ?? Formations::slots($name);
        $free = array_keys($slots);
        $on = array_keys(array_filter($team['players'], fn ($p) => $p['on']));

        usort($on, fn ($a, $b) => ($team['players'][$b]['slot_line'] === 'gk') <=> ($team['players'][$a]['slot_line'] === 'gk')
            ?: $team['players'][$b]['a']['ovr'] <=> $team['players'][$a]['a']['ovr']);

        foreach ($on as $i) {
            $p = $team['players'][$i];
            $best = null;
            foreach ($free as $k => $slotIndex) {
                $slot = $slots[$slotIndex];
                $fit = ($p['slot_line'] === 'gk') === ($slot['line'] === 'gk') ? -AutoPick::misfit($p, $slot) : -100000;
                if ($best === null || $fit > $best[0]) {
                    $best = [$fit, $k];
                }
            }
            if ($best === null) {
                break;
            }
            $slotIndex = $free[$best[1]];
            unset($free[$best[1]]);
            $team['players'][$i]['slot'] = $slotIndex;
            $team['players'][$i]['slot_line'] = $slots[$slotIndex]['line'];
        }
        $team['formation'] = $name;
        if ($own !== null) {
            $team['slots'] = $own;
        } else {
            unset($team['slots']);
        }

        return null;
    }

    /** Eleven slots, the goalkeeper alone in goal and first, each with its role, line and place. */
    private static function validSlots(mixed $slots): bool
    {
        if (! is_array($slots) || count($slots) !== 11 || ! array_is_list($slots)) {
            return false;
        }
        foreach ($slots as $i => $slot) {
            if (! is_array($slot) || ! is_string($slot['role'] ?? null) || ! is_int($slot['x'] ?? null) || ! is_int($slot['y'] ?? null)
                || ! in_array($slot['line'] ?? null, ['gk', 'def', 'mid', 'att'], true) || ($slot['line'] === 'gk') !== ($i === 0)) {
                return false;
            }
        }

        return true;
    }
}
