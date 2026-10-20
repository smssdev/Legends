<?php

namespace App\Simulator;

use App\Engine\MatchSetup;

/**
 * Golden matches (docs/ENGINE.md 9, PLAN 2.12): made-up squads and a frozen
 * config snapshot, so the recording depends on the engine code only. The
 * fingerprint of every minute must be the same on every processor (x86 and
 * ARM); a change in the engine code changes it and needs a new engine version
 * and `php artisan sim:golden --write`.
 */
class Golden
{
    public const FILE = 'tests/fixtures/engine-golden.json';

    /** The cases: seed, competition (cup reaches extra time and penalties more often), referee, home tactics. */
    public const CASES = [
        [1, 'league', 1, []],
        [42, 'league', 0, ['plan' => 'counter', 'pressing' => 90, 'tackling' => 3]],
        [48213, 'league', 2, ['plan' => 'shots', 'tempo' => 80, 'trap' => 1]],
        [7, 'cup', 1, ['plan' => 'wings', 'style' => 20]],
        [99, 'cup', 2, ['plan' => 'long', 'marking' => 'man']],
    ];

    public static function squad(int $base, int $ovr): array
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];

        return array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P$i", 'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
            'overall' => $ovr - intdiv($i, 3), 'pac' => 60 + ($i * 7) % 30, 'sho' => 55 + ($i * 5) % 35, 'pas' => 60 + ($i * 3) % 30,
            'dri' => 62 + ($i * 11) % 28, 'def' => 50 + ($i * 13) % 40, 'phy' => 60 + ($i * 17) % 30,
            'gk_diving' => 75, 'gk_handling' => 74, 'gk_positioning' => 76, 'gk_reflexes' => 78,
            'penalties' => 70, 'free_kick' => 65, 'crossing' => 65, 'heading' => 66, 'stamina' => 75, 'aggression' => 60,
        ], $positions, array_keys($positions));
    }

    public static function state(array $case, array $snapshot): array
    {
        [$seed, $competition, $referee, $tactics] = $case;
        $club = fn ($id) => ['id' => $id, 'name' => "C$id", 'code' => 'C'.$id, 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];

        return MatchSetup::build(
            ['club' => $club(1), 'squad' => self::squad(100, 82)] + ($tactics ? ['tactics' => $tactics] : []),
            ['club' => $club(2), 'squad' => self::squad(200, 80)],
            ['seed' => $seed, 'competition' => $competition, 'referee' => $referee],
            $snapshot,
        );
    }

    /** Plays a case to the end: final score and the SHA-256 of every minute as JSON. */
    public static function play(array $case, array $snapshot): array
    {
        [$state, $ticks] = Runner::toEnd(self::state($case, $snapshot));

        return ['seed' => $case[0], 'competition' => $case[1], 'minutes' => count($ticks), 'score' => $state['score'],
            'shootout' => $state['shootout'], 'sha256' => hash('sha256', json_encode($ticks))];
    }
}
