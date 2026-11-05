<?php

namespace App\League;

use Random\Engine\Mt19937;
use Random\Randomizer;

/**
 * The cup's bracket [PLAN 2.5]: single matches, knock-out. With n teams and S the largest power of two up
 * to n (at most 16), the weakest 2 × (n − S) play a preliminary round and the rest go straight to the
 * round of S. The draw is random among those in the same round, from the season's own seed, so a season
 * always gets the same draw. Pure: clubs in, ties out.
 */
class CupBracket
{
    public const NAMES = [32 => 'r32', 16 => 'r16', 8 => 'qf', 4 => 'sf', 2 => 'final'];

    /** The stages in the order they are played, the preliminary first when there is one. */
    public static function stages(int $teams): array
    {
        $size = self::mainSize($teams);
        $stages = $teams > $size ? ['preliminary'] : [];
        for ($s = $size; $s >= 2; $s = intdiv($s, 2)) {
            $stages[] = self::NAMES[$s];
        }

        return $stages;
    }

    public static function mainSize(int $teams): int
    {
        $s = 1;
        while ($s * 2 <= min($teams, 16)) {
            $s *= 2;
        }

        return $s;
    }

    /**
     * @param  list<int>  $clubs  strongest first (strength at the start of the season)
     * @return list<array{stage: string, slot: int, home: ?int, away: ?int, next: ?array{0: string, 1: int, 2: string}}>
     *                                                                                                                   every tie; next = [stage, slot, side] the winner moves to
     */
    public static function draw(array $clubs, int $seed): array
    {
        $rng = new Randomizer(new Mt19937($seed));
        $n = count($clubs);
        $size = self::mainSize($n);
        $stages = self::stages($n);
        $ties = [];
        $entrants = $clubs;
        if ($n > $size) {
            $playing = 2 * ($n - $size);
            $exempt = array_slice($clubs, 0, $n - $playing);
            $weak = $rng->shuffleArray(array_slice($clubs, $n - $playing));
            $entrants = array_map(fn ($c) => ['club' => $c], $exempt);
            foreach (array_chunk($weak, 2) as $i => [$home, $away]) {
                $ties[] = ['stage' => 'preliminary', 'slot' => $i + 1, 'home' => $home, 'away' => $away, 'next' => null];
                $entrants[] = ['tie' => count($ties) - 1];
            }
        } else {
            $entrants = array_map(fn ($c) => ['club' => $c], $clubs);
        }

        // The first main round [Sprint 43 C3, Hamza 2026-11-05]: no branch all strong and another all weak. The
        // strongest half are seeds, one in each tie, spread by the bracket's seeding (the first two in opposite
        // halves, the first four in different quarters...), drawn within each level; the rest (the preliminary
        // winners among them) are drawn against them.
        $main = array_search(self::NAMES[$size], $stages, true);
        $half = intdiv(count($entrants), 2);
        $seeds = array_slice($entrants, 0, $half);
        $others = $rng->shuffleArray(array_slice($entrants, $half));
        $places = self::seeding($half);
        $byTie = [];
        for ($from = 0, $level = 1; $from < $half; $from += $level, $level = $from) {
            $tier = array_slice(range(0, $half - 1), $from, $level);
            foreach (array_values($rng->shuffleArray($tier)) as $k => $seed) {
                $byTie[$places[$from + $k]] = $seeds[$seed];
            }
        }
        $pairs = [];
        for ($i = 0; $i < $half; $i++) {
            $pairs[] = [$byTie[$i], $others[$i]];
        }
        foreach ($pairs as $i => $pair) {
            $tie = ['stage' => $stages[$main], 'slot' => $i + 1, 'home' => null, 'away' => null, 'next' => null];
            foreach ([0 => 'home', 1 => 'away'] as $k => $side) {
                if (isset($pair[$k]['club'])) {
                    $tie[$side] = $pair[$k]['club'];
                } else {
                    $ties[$pair[$k]['tie']]['next'] = [$stages[$main], $i + 1, $side];
                }
            }
            $ties[] = $tie;
        }
        // Then the bracket: the winners of slots 2k−1 and 2k meet in slot k of the next stage.
        for ($j = $main; $j < count($stages) - 1; $j++) {
            $count = intdiv($size, 2 ** ($j - $main + 1));
            for ($slot = 1; $slot <= $count; $slot++) {
                foreach ($ties as &$t) {
                    if ($t['stage'] === $stages[$j] && $t['slot'] === $slot) {
                        $t['next'] = [$stages[$j + 1], intdiv($slot + 1, 2), $slot % 2 === 1 ? 'home' : 'away'];
                    }
                }
                unset($t);
                if ($slot % 2 === 0) {
                    $ties[] = ['stage' => $stages[$j + 1], 'slot' => intdiv($slot, 2), 'home' => null, 'away' => null, 'next' => null];
                }
            }
        }

        return $ties;
    }

    /**
     * The tie (0-based) of each seed (0-based) in a round of $ties ties: the bracket's seeding, so the first two meet
     * only in the final, the first four only in the semi-finals, and so on. Pure.
     *
     * @return list<int> [seed index => tie index]
     */
    public static function seeding(int $ties): array
    {
        $order = [1];
        while (count($order) < $ties) {
            $n = count($order) * 2;
            $next = [];
            foreach ($order as $seed) {
                $next[] = $seed;
                $next[] = $n + 1 - $seed;
            }
            $order = $next;
        }
        $places = [];
        foreach ($order as $tie => $seed) {
            $places[$seed - 1] = $tie;
        }
        ksort($places);

        return array_values($places);
    }
}
