<?php

namespace App\Engine;

/**
 * Builds the initial engine state for a match from two squads. The result is
 * plain integer arrays (JSON-safe), so a match can be stored, cached and
 * replayed from seed + setup + actions.
 */
final class MatchSetup
{
    public const DEFAULT_TACTICS = [
        'plan' => 'passing',       // counter | long | passing | wings | shots
        'tackling' => 1,           // 0 legal, 1 normal, 2 eager, 3 hard
        'pressing' => 50,          // 0..100
        'style' => 50,             // 0 defensive .. 100 attacking
        'tempo' => 50,             // 0..100
        'att' => 'support',        // back | support | only
        'mid' => 'stay',           // def | stay | push
        'def' => 'stay',           // stay | fullbacks | mid
        'trap' => 0,               // offside trap 0/1
        'marking' => 'zone',       // zone | man
    ];

    /**
     * @param  array  $home  ['club' => [...], 'squad' => [...], optional 'formation', 'starters', 'bench', 'tactics',
     *                       and 'slots' (a league formation's own slots, App\League\FormationBook) with 'takers']
     * @param  array  $options  seed, competition (league|cup), referee (0..4: very lenient to very strict, Sprint 38 E7), venue (home|neutral), pitch (the home stadium's pitch stage, 0..3)
     * @param  array  $cfg  config snapshot: ['match' => ..., 'engine' => ...]
     */
    public static function build(array $home, array $away, array $options, array $cfg): array
    {
        $state = [
            'v' => (int) ($cfg['engine']['version'] ?? 1),
            'seed' => (int) $options['seed'],
            'cfg' => $cfg,
            'competition' => $options['competition'] ?? 'league',
            'referee' => (int) ($options['referee'] ?? 2),
            'venue' => $options['venue'] ?? 'home',
            'pitch' => (int) ($options['pitch'] ?? 0),
            'tick' => 0,
            'period' => 1,
            'pmin' => 0,
            'stoppage' => [1 => 0, 2 => 0, 3 => 0, 4 => 0],
            'finished' => false,
            'score' => ['home' => 0, 'away' => 0],
            'shootout' => null,
            'momentum' => [],
            'thirds' => [0, 0, 0],
            'teams' => [
                'home' => self::team('home', $home, $cfg),
                'away' => self::team('away', $away, $cfg),
            ],
        ];
        FloatGuard::check($state);

        return $state;
    }

    private static function team(string $side, array $input, array $cfg): array
    {
        $squad = array_map(fn ($p) => self::player($p), $input['squad']);
        // A league match brings its frozen sheet: the formation's slots, the eleven, the bench (Sprint 18).
        // The simulator brings a name of the engine's own six and may leave the rest to AutoPick.
        $own = isset($input['slots']);
        $pick = $own ? null : AutoPick::pick($squad, $input['formation'] ?? null);
        $formation = $own ? (string) $input['formation'] : $pick['formation'];
        $starters = $input['starters'] ?? $pick['starters'];
        $bench = $input['bench'] ?? $pick['bench'];
        $slots = $own ? $input['slots'] : Formations::slots($formation);

        $byId = [];
        foreach ($squad as $p) {
            $byId[$p['id']] = $p;
        }

        $players = [];
        foreach ($starters as $i => $id) {
            $p = $byId[$id];
            $p['no'] = $i + 1;
            $p['on'] = true;
            $p['slot'] = $i;
            $p['slot_line'] = $slots[$i]['line'];
            $players[] = $p;
        }
        foreach ($bench as $j => $id) {
            $p = $byId[$id];
            $p['no'] = 12 + $j;
            $p['on'] = false;
            $p['slot'] = null;
            $p['slot_line'] = $p['line'];
            $players[] = $p;
        }

        $team = [
            'side' => $side,
            'club' => $input['club'],
            'formation' => $formation,
            'tactics' => array_merge(self::DEFAULT_TACTICS, $input['tactics'] ?? []),
            'players' => $players,
            'takers' => isset($input['takers']) ? $input['takers'] + AutoPick::takers($players) : AutoPick::takers($players),
            'subs_used' => 0,
            'subs_max' => (int) ($cfg['match']['subs'] ?? 3),
            'missing' => 0,
            'stats' => array_fill_keys([
                'attacks', 'builds', 'builds_lost', 'presses_won', 'counters', 'progress', 'chances', 'big_chances',
                'shots', 'on_target', 'goals', 'corners', 'fouls', 'yellow', 'red', 'offsides', 'saves', 'xg',
            ], 0),
        ];
        // Only a league side carries its slots; the simulator's states keep their old shape.
        if ($own) {
            $team['slots'] = $slots;
        }
        // The eleven's chemistry, 0..100 [X22], when the caller measured it (App\League\Chemistry).
        if (isset($input['chem'])) {
            $team['chem'] = max(0, min(100, (int) $input['chem']));
        }
        // Its morale for this match, 0..100 [X25], with the crowd and the tickets (App\League\Morale).
        if (isset($input['morale'])) {
            $team['morale'] = max(0, min(100, (int) $input['morale']));
        }
        // A referee it bought, past the VAR [X28] (App\League\Integrity).
        if (! empty($input['bribed'])) {
            $team['bribed'] = 1;
        }

        return $team;
    }

    /** A team's slots: its own (a league formation) or the engine template's. */
    public static function slots(array $team): array
    {
        return $team['slots'] ?? Formations::slots($team['formation']);
    }

    /** Normalises a player row (from master_players) into the engine shape. */
    public static function player(array $r): array
    {
        $gk = $r['line'] === 'gk';
        $gkAvg = $gk ? intdiv(($r['gk_diving'] ?? 50) + ($r['gk_handling'] ?? 50) + ($r['gk_positioning'] ?? 50) + ($r['gk_reflexes'] ?? 50), 4) : 25;
        $field = fn ($key, $fallback) => (int) ($r[$key] ?? $fallback);

        return [
            'id' => (int) $r['id'],
            'name' => (string) $r['name'],
            'pos' => (string) $r['position'],
            'alt' => (string) ($r['alt_positions'] ?? ''),
            'line' => (string) $r['line'],
            'age' => (int) $r['age'],
            'fit' => 10000,
            'yc' => 0,
            'out' => '',              // '' | sub | red | injury
            'a' => [
                'ovr' => (int) $r['overall'],
                'pac' => $field('pac', $gk ? 40 : 50), 'sho' => $field('sho', $gk ? 20 : 50), 'pas' => $field('pas', $gk ? 45 : 50),
                'dri' => $field('dri', $gk ? 25 : 50), 'def' => $field('def', $gk ? 30 : 50), 'phy' => $field('phy', $gk ? 55 : 50),
                'gk' => $gkAvg,
                'pen' => $field('penalties', 30), 'fk' => $field('free_kick', 30), 'cross' => $field('crossing', 40),
                'head' => $field('heading', 40), 'sta' => $field('stamina', 60), 'agg' => $field('aggression', 50),
            ],
            'st' => ['touches' => 0, 'shots' => 0, 'on_target' => 0, 'goals' => 0, 'assists' => 0, 'key' => 0,
                'tackles' => 0, 'fouls' => 0, 'saves' => 0, 'r' => 600],
        ];
    }
}
