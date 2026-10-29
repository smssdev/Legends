<?php

namespace App\League;

use App\Engine\MatchEngine;

/**
 * The tactics book [Sprint 21 E5.4]: each attack plan, the defensive shapes it beats and the ones that stop it, read
 * from the engine's own table (engine.matchup_cp) and its own rule for the shape, so the book can never say what the
 * match does not do. The weaker side's answer is the plan that beats the stronger side's shape: an edge in the chances
 * it makes, never in its players' strength.
 */
class TacticsBook
{
    public const SHAPES = ['high', 'mid', 'low'];

    /** Plans as the tactics name them, keyed to the engine table's names. */
    private const KEYS = ['counter' => 'counter', 'long' => 'long_balls', 'passing' => 'passing', 'wings' => 'wings', 'shots' => 'long_shots'];

    /**
     * plans: per plan, its edge against each shape (hundredths of a rating point), and the shapes it beats and loses to;
     * shapes: per shape, the plans that beat it (best first) and the ones it stops; mine: the shape of these tactics.
     *
     * @param  array<string, mixed>|null  $tactics
     */
    public static function build(array $engine, ?array $tactics = null): array
    {
        $plans = [];
        foreach (self::KEYS as $plan => $key) {
            $row = array_map('intval', $engine['matchup_cp'][$key] ?? [0, 0, 0]);
            $edge = array_combine(self::SHAPES, $row);
            $plans[] = ['plan' => $plan, 'edge' => $edge,
                'beats' => array_keys(array_filter($edge, fn ($v) => $v > 0)), 'loses_to' => array_keys(array_filter($edge, fn ($v) => $v < 0))];
        }
        $shapes = [];
        foreach (self::SHAPES as $shape) {
            $order = collect($plans)->sortByDesc(fn ($p) => $p['edge'][$shape])->values();
            $shapes[] = ['shape' => $shape,
                'beaten_by' => $order->filter(fn ($p) => $p['edge'][$shape] > 0)->pluck('plan')->all(),
                'stops' => $order->filter(fn ($p) => $p['edge'][$shape] < 0)->pluck('plan')->reverse()->values()->all()];
        }
        $mine = $tactics ? self::SHAPES[MatchEngine::shape($tactics)] : null;

        return ['plans' => $plans, 'shapes' => $shapes, 'mine' => $mine];
    }
}
