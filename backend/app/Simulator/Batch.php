<?php

namespace App\Simulator;

use App\Models\MasterClub;

/**
 * Runs many matches and aggregates what calibration needs (docs/ENGINE.md 9):
 * results, goals, shots, cards, penalties, late goals, fatigue.
 */
class Batch
{
    public static function run(MasterClub $home, MasterClub $away, int $n, array $options = [], array $overrides = [], int $seedFrom = 1): array
    {
        $base = MatchFactory::make($home, $away, ['seed' => 0] + $options, $overrides);
        $m = ['n' => $n, 'home_win' => 0, 'draw' => 0, 'away_win' => 0, 'goals_home' => 0, 'goals_away' => 0, 'nil_nil' => 0,
            'shots' => 0, 'on_target' => 0, 'yellow' => 0, 'red' => 0, 'penalties' => 0, 'injuries' => 0, 'offsides' => 0,
            'corners' => 0, 'fouls' => 0, 'goals' => 0, 'late_goals' => 0, 'attacks_home' => 0, 'attacks_away' => 0,
            'presses_won_home' => 0, 'counters_home' => 0, 'counters_away' => 0, 'fitness_home' => 0, 'fitness_away' => 0,
            'yellow_home' => 0, 'yellow_away' => 0, 'red_home' => 0, 'red_away' => 0, 'added' => 0];

        for ($i = 0; $i < $n; $i++) {
            $state = $base;
            $state['seed'] = $seedFrom + $i;
            [$state, $ticks] = Runner::toEnd($state);
            $h = $state['score']['home'];
            $a = $state['score']['away'];
            if ($state['shootout']) {
                $h += $state['shootout']['home'] > $state['shootout']['away'] ? 1 : 0;
                $a += $state['shootout']['away'] > $state['shootout']['home'] ? 1 : 0;
            }
            $m[$h > $a ? 'home_win' : ($h < $a ? 'away_win' : 'draw')]++;
            $m['goals_home'] += $state['score']['home'];
            $m['goals_away'] += $state['score']['away'];
            $m['nil_nil'] += ($state['score']['home'] + $state['score']['away']) === 0 ? 1 : 0;

            foreach (['home', 'away'] as $side) {
                $st = $state['teams'][$side]['stats'];
                foreach (['shots', 'on_target', 'yellow', 'red', 'offsides', 'corners', 'fouls'] as $k) {
                    $m[$k] += $st[$k];
                }
                $m["attacks_$side"] += $st['attacks'];
                $m["counters_$side"] += $st['counters'];
                $m["yellow_$side"] += $st['yellow'];
                $m["red_$side"] += $st['red'];
                $fit = array_filter($state['teams'][$side]['players'], fn ($p) => $p['on']);
                $m["fitness_$side"] += $fit ? intdiv(array_sum(array_column($fit, 'fit')), count($fit)) : 0;
            }
            $m['presses_won_home'] += $state['teams']['home']['stats']['presses_won'];
            $m['added'] += $state['stoppage'][1] + $state['stoppage'][2];

            foreach ($ticks as $tick) {
                foreach ($tick['events'] as $e) {
                    if ($e['type'] === 'goal') {
                        $m['goals']++;
                        $m['late_goals'] += $tick['minute'][0] >= 76 && $tick['period'] === 2 ? 1 : 0;
                    }
                    $m['penalties'] += $e['type'] === 'penalty' ? 1 : 0;
                    $m['injuries'] += $e['type'] === 'injury' ? 1 : 0;
                }
            }
        }

        return $m;
    }

    /** Per-match averages and percentages for printing. */
    public static function summary(array $m): array
    {
        $n = max(1, $m['n']);
        $pct = fn ($k) => round(100 * $m[$k] / $n, 1);
        $avg = fn ($k) => round($m[$k] / $n, 2);

        return [
            'matches' => $n,
            'home_win_%' => $pct('home_win'), 'draw_%' => $pct('draw'), 'away_win_%' => $pct('away_win'),
            'goals/match' => round(($m['goals_home'] + $m['goals_away']) / $n, 2),
            'goals_home' => $avg('goals_home'), 'goals_away' => $avg('goals_away'), '0-0_%' => $pct('nil_nil'),
            'shots/team' => round($m['shots'] / $n / 2, 1), 'on_target/team' => round($m['on_target'] / $n / 2, 1),
            'yellow/match' => $avg('yellow'), 'red/match' => $avg('red'), 'penalties/match' => $avg('penalties'),
            'injuries/match' => $avg('injuries'), 'offsides/match' => $avg('offsides'), 'corners/match' => $avg('corners'),
            'fouls/match' => $avg('fouls'), 'late_goals_%' => $m['goals'] ? round(100 * $m['late_goals'] / $m['goals'], 1) : 0,
            'attacks_home' => $avg('attacks_home'), 'attacks_away' => $avg('attacks_away'),
            'counters_home' => $avg('counters_home'), 'counters_away' => $avg('counters_away'),
            'yellow_home' => $avg('yellow_home'), 'yellow_away' => $avg('yellow_away'),
            'red_home_%' => $pct('red_home'), 'red_away_%' => $pct('red_away'),
            'fitness_end_home_%' => round($m['fitness_home'] / $n / 100, 1), 'fitness_end_away_%' => round($m['fitness_away'] / $n / 100, 1),
            'added_minutes' => $avg('added'),
        ];
    }
}
