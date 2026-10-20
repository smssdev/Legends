<?php

namespace App\Data;

/**
 * A player's value in club money [PLAN 2.6]: the rating sets the price, then age, line and room
 * to grow move it. A pure function on integers: the same player is worth the same everywhere.
 * The numbers live in config('game.valuation') and are passed in, so tests and leagues can pin them.
 */
class PlayerValuation
{
    public function __construct(private array $config) {}

    public static function fromConfig(): self
    {
        return new self(config('game.valuation'));
    }

    public function value(int $overall, int $age, string $line, int $potential): int
    {
        $value = $this->base($overall);
        $value = intdiv($value * $this->step($this->config['age_bp'], $age), 10000);
        $value = intdiv($value * ($this->config['line_bp'][$line] ?? 10000), 10000);
        $room = max(0, $potential - $overall);
        $value = intdiv($value * (10000 + $room * $this->config['potential_bp_per_point']), 10000);

        return $this->round($value);
    }

    /** The value for a rating, in a straight line between the two nearest points of the table. */
    private function base(int $overall): int
    {
        $table = $this->config['by_overall'];
        ksort($table);
        $points = array_keys($table);
        if ($overall <= $points[0]) {
            return $table[$points[0]];
        }
        for ($i = 1; $i < count($points); $i++) {
            [$lo, $hi] = [$points[$i - 1], $points[$i]];
            if ($overall <= $hi) {
                return $table[$lo] + intdiv(($table[$hi] - $table[$lo]) * ($overall - $lo), $hi - $lo);
            }
        }

        return $table[end($points)];
    }

    /** The value of a step table at x: the entry of the largest key not above x. */
    private function step(array $table, int $x): int
    {
        ksort($table);
        $out = reset($table);
        foreach ($table as $from => $v) {
            if ($x >= $from) {
                $out = $v;
            }
        }

        return $out;
    }

    private function round(int $value): int
    {
        foreach ($this->config['round_to'] as $below => $step) {
            if ($value < $below) {
                return max($step, intdiv($value + intdiv($step, 2), $step) * $step);
            }
        }

        return $value;
    }
}
