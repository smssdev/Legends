<?php

namespace App\Engine;

/**
 * Integer-only xorshift32 generator. Seeded from the match seed and the tick
 * number, so a minute always replays identically on any machine. Shifts and
 * xors only: no multiplication that could overflow into a float.
 */
final class SeededRandom
{
    private int $state;

    public function __construct(int $seed)
    {
        $this->state = ($seed & 0xFFFFFFFF) ?: 0x9E3779B9;
    }

    public static function forTick(int $matchSeed, int $tick, int $stream = 0): self
    {
        return new self(crc32($matchSeed.':'.$tick.':'.$stream));
    }

    public function next(): int
    {
        $x = $this->state;
        $x ^= ($x << 13) & 0xFFFFFFFF;
        $x ^= $x >> 17;
        $x ^= ($x << 5) & 0xFFFFFFFF;

        return $this->state = $x & 0xFFFFFFFF;
    }

    /** Uniform integer in [0, $n). */
    public function int(int $n): int
    {
        return $n <= 1 ? 0 : $this->next() % $n;
    }

    /** True with probability $bp / 10000. */
    public function chance(int $bp): bool
    {
        return $this->int(10000) < $bp;
    }

    /** Picks an index from integer weights. */
    public function weighted(array $weights): int|string
    {
        $total = array_sum($weights);
        $roll = $this->int(max(1, $total));
        foreach ($weights as $key => $w) {
            if ($roll < $w) {
                return $key;
            }
            $roll -= $w;
        }

        return array_key_first($weights);
    }
}
