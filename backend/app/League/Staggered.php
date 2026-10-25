<?php

namespace App\League;

/**
 * A round in two time slots [X31]: half its matches at the round's time, the other half after the league's gap.
 * Fair by construction: each round the second slot takes the matches of the clubs that have played the most in
 * the first (so every club ends the season with as many of each, or one apart), the strongest pairing first when
 * that is even; and the last round is played all at once, so the title and the places are settled together.
 */
class Staggered
{
    /**
     * @param  list<list<array{0: int, 1: int}>>  $rounds  each round's matches [home, away]
     * @param  array<int, int>  $strength  club => strength, for the night's pairing when the balance is even
     * @return list<list<int>> each round's slot per match (1 or 2)
     */
    public static function split(array $rounds, array $strength): array
    {
        $first = [];
        $second = [];
        $out = [];
        $last = count($rounds) - 1;
        foreach ($rounds as $r => $matches) {
            $slots = array_fill(0, count($matches), 1);
            if ($r !== $last && count($matches) >= 2) {
                $score = [];
                foreach ($matches as $i => [$h, $a]) {
                    // Who owes the second slot most: first-slot matches over second-slot ones, both clubs.
                    $owed = ($first[$h] ?? 0) - ($second[$h] ?? 0) + ($first[$a] ?? 0) - ($second[$a] ?? 0);
                    $score[$i] = [$owed, ($strength[$h] ?? 0) + ($strength[$a] ?? 0), -$i];
                }
                uksort($score, fn ($x, $y) => $score[$y] <=> $score[$x]);
                // An odd number of matches: the extra one goes to each slot in turn, round after round.
                foreach (array_slice(array_keys($score), 0, intdiv(count($matches) + $r % 2, 2)) as $i) {
                    $slots[$i] = 2;
                }
            }
            foreach ($matches as $i => [$h, $a]) {
                $bucket = $slots[$i] === 2 ? 'second' : 'first';
                foreach ([$h, $a] as $club) {
                    ${$bucket}[$club] = (${$bucket}[$club] ?? 0) + 1;
                }
            }
            $out[] = $slots;
        }

        return self::repair($rounds, $out);
    }

    /**
     * Then a polish: within a round, a first-slot match and a second-slot one change places whenever that brings the
     * clubs' counts closer (the sum of each club's difference squared goes down), until no swap helps. The greedy
     * pass looks one round ahead only; this settles what it left uneven.
     */
    private static function repair(array $rounds, array $slots): array
    {
        $d = [];
        $last = count($rounds) - 1;
        foreach ($rounds as $r => $matches) {
            foreach ($matches as $i => [$h, $a]) {
                $v = $slots[$r][$i] === 1 ? 1 : -1;
                $d[$h] = ($d[$h] ?? 0) + $v;
                $d[$a] = ($d[$a] ?? 0) + $v;
            }
        }
        // The last round counts for everyone alike (all in one slot): left out of the balance.
        foreach ($rounds[$last] ?? [] as [$h, $a]) {
            $d[$h]--;
            $d[$a]--;
        }
        for ($pass = 0, $better = true; $better && $pass < 200; $pass++) {
            $better = false;
            foreach ($rounds as $r => $matches) {
                if ($r === $last) {
                    continue;
                }
                foreach ($matches as $i => [$h1, $a1]) {
                    foreach ($matches as $j => [$h2, $a2]) {
                        if ($slots[$r][$i] !== 1 || $slots[$r][$j] !== 2) {
                            continue;
                        }
                        // Match i goes to the second slot (its clubs -2), match j to the first (+2).
                        $change = [$h1 => -2, $a1 => -2];
                        foreach ([$h2, $a2] as $c) {
                            $change[$c] = ($change[$c] ?? 0) + 2;
                        }
                        $gain = 0;
                        foreach ($change as $c => $x) {
                            $gain += ($d[$c] + $x) ** 2 - $d[$c] ** 2;
                        }
                        if ($gain < 0) {
                            foreach ($change as $c => $x) {
                                $d[$c] += $x;
                            }
                            [$slots[$r][$i], $slots[$r][$j]] = [2, 1];
                            $better = true;
                        }
                    }
                }
            }
        }

        return $slots;
    }
}
