<?php

namespace App\League;

/**
 * Home and away league rounds by the circle method [PLAN 2.4]. One team stays put and the others turn
 * around it; with an odd count a "rest" seat joins the circle, so each team rests once in each half.
 * The second half is the first again with home and away swapped. Pure and deterministic.
 */
class RoundRobin
{
    /**
     * @param  list<int>  $teams
     * @return list<array{matches: list<array{0: int, 1: int}>, rest: ?int}> one entry per round
     */
    public static function rounds(array $teams): array
    {
        $seats = array_values($teams);
        if (count($seats) % 2 === 1) {
            $seats[] = null;
        }
        $n = count($seats);
        $half = [];
        for ($r = 0; $r < $n - 1; $r++) {
            $matches = [];
            $rest = null;
            for ($i = 0; $i < $n / 2; $i++) {
                [$a, $b] = [$seats[$i], $seats[$n - 1 - $i]];
                if ($a === null || $b === null) {
                    $rest = $a ?? $b;

                    continue;
                }
                // The fixed seat swaps sides every round; the others by their place, so home and away even out.
                $matches[] = ($i === 0 ? $r % 2 === 0 : $i % 2 === 1) ? [$a, $b] : [$b, $a];
            }
            $half[] = ['matches' => $matches, 'rest' => $rest];
            // Keep seat 0, turn the rest one step.
            $seats = array_merge([$seats[0]], [$seats[$n - 1]], array_slice($seats, 1, $n - 2));
        }
        $second = array_map(fn ($round) => ['matches' => array_map(fn ($m) => [$m[1], $m[0]], $round['matches']), 'rest' => $round['rest']], $half);

        return array_merge($half, $second);
    }
}
