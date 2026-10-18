<?php

namespace App\Simulator;

/**
 * Simple match-day rules for a team the computer manages (docs/ENGINE.md 7):
 * tired players come off from minute 60, a trailing team pushes from 70 and
 * a leading team protects the lead from 80. Its decisions are ordinary orders.
 */
class CpuCoach
{
    public static function orders(array $state, string $side): array
    {
        $team = $state['teams'][$side];
        $other = $side === 'home' ? 'away' : 'home';
        $minute = $state['out']['minute'][0] ?? 0;
        $diff = $state['score'][$side] - $state['score'][$other];
        $orders = [];

        if ($minute >= 60 && $team['subs_used'] < $team['subs_max'] && $state['tick'] % 4 === 0) {
            $tired = null;
            foreach ($team['players'] as $p) {
                if ($p['on'] && $p['slot_line'] !== 'gk' && $p['fit'] < 6500 && ($tired === null || $p['fit'] < $tired['fit'])) {
                    $tired = $p;
                }
            }
            if ($tired) {
                $sub = null;
                foreach ($team['players'] as $p) {
                    if (! $p['on'] && $p['out'] === '' && $p['slot'] === null && $p['line'] !== 'gk') {
                        $score = $p['a']['ovr'] + ($p['line'] === $tired['slot_line'] ? 20 : 0);
                        if ($sub === null || $score > $sub[0]) {
                            $sub = [$score, $p['id']];
                        }
                    }
                }
                if ($sub) {
                    $orders[] = ['type' => 'sub', 'team' => $side, 'out' => $tired['id'], 'in' => $sub[1]];
                }
            }
        }

        $t = $team['tactics'];
        if ($minute >= 70 && $diff < 0 && $t['style'] < 75) {
            $orders[] = ['type' => 'tactics', 'team' => $side, 'tactics' => ['style' => 80, 'tempo' => 70]];
        } elseif ($minute >= 80 && $diff > 0 && $t['style'] > 35) {
            $orders[] = ['type' => 'tactics', 'team' => $side, 'tactics' => ['style' => 30, 'tempo' => 35]];
        }

        return $orders;
    }
}
