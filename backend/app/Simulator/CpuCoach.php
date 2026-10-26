<?php

namespace App\Simulator;

/**
 * Simple match-day rules for a team the computer manages (docs/ENGINE.md 7):
 * tired players come off from minute 60, a trailing team pushes from 70 and
 * a leading team protects the lead from 80 (75, the last window, in a match with windows). Its decisions are
 * ordinary orders.
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

        // [X42] With windows it changes only in them (MatchOrders), so it rests every tired player there at once;
        // without, one now and then.
        $windows = CoachWindows::used($state);
        if ($minute >= 60 && $team['subs_used'] < $team['subs_max'] && ($windows || $state['tick'] % 4 === 0)) {
            $tired = array_filter($team['players'], fn ($p) => $p['on'] && $p['slot_line'] !== 'gk' && $p['fit'] < 6500);
            usort($tired, fn ($a, $b) => $a['fit'] <=> $b['fit']);
            $left = $windows ? $team['subs_max'] - $team['subs_used'] : 1;
            $used = [];
            foreach (array_slice($tired, 0, $left) as $out) {
                $sub = null;
                foreach ($team['players'] as $p) {
                    if (! $p['on'] && $p['out'] === '' && $p['slot'] === null && $p['line'] !== 'gk' && ! in_array($p['id'], $used, true)) {
                        $score = $p['a']['ovr'] + ($p['line'] === $out['slot_line'] ? 20 : 0);
                        if ($sub === null || $score > $sub[0]) {
                            $sub = [$score, $p['id']];
                        }
                    }
                }
                if ($sub) {
                    $used[] = $sub[1];
                    $orders[] = ['type' => 'sub', 'team' => $side, 'out' => $out['id'], 'in' => $sub[1]];
                }
            }
        }

        $t = $team['tactics'];
        if ($minute >= 70 && $diff < 0 && $t['style'] < 75) {
            $orders[] = ['type' => 'tactics', 'team' => $side, 'tactics' => ['style' => 80, 'tempo' => 70]];
        } elseif ($minute >= ($windows ? 75 : 80) && $diff > 0 && $t['style'] > 35) {
            $orders[] = ['type' => 'tactics', 'team' => $side, 'tactics' => ['style' => 30, 'tempo' => 35]];
        }

        return $orders;
    }
}
