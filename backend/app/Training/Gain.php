<?php

namespace App\Training;

/**
 * One training session in numbers [PLAN 2.8]: how far a player's bar moves. Pure and on integers. The harder the
 * stronger he is (sessions_by_overall: about 6 sessions at 65, about 25 at 89), each session a random step from
 * half to one and a half of the average, drawn from the session's own key so a replayed session moves the same.
 * Open training [X16]: past the potential he still grows, much slower, up to the ceiling (99). Age [Sprint 23], the
 * strongest factor: the young take bigger steps, from 29 smaller and smaller (age_step_bp).
 */
class Gain
{
    public function __construct(private array $config) {}

    public static function fromConfig(): self
    {
        return new self(config('game.training'));
    }

    /** The rating no training goes past [X16]. */
    public function ceiling(): int
    {
        return (int) ($this->config['ceiling'] ?? 99);
    }

    /** About how many sessions a +1 takes at this rating; at or past the potential, many more [X16]. */
    public function sessions(int $overall, ?int $potential = null): int
    {
        $base = $this->baseSessions($overall);
        if ($potential === null || $overall < $potential) {
            return $base;
        }

        return $base * (1 + (int) ($this->config['over_potential_factor'] ?? 2) * ($overall - $potential + 1));
    }

    private function baseSessions(int $overall): int
    {
        $table = $this->config['sessions_by_overall'];
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

    /** The bar's step for one session (out of progress_scale), at this age when known. */
    public function step(int $overall, string $key, ?int $potential = null, ?int $age = null): int
    {
        $scale = (int) $this->config['progress_scale'];
        $average = intdiv(intdiv($scale, max(1, $this->sessions($overall, $potential))) * $this->ageBp($age), 10000);
        [$lo, $hi] = $this->config['step_bp'];

        return intdiv($average * ($lo + crc32($key) % ($hi - $lo + 1)), 10000);
    }

    /** The step at this age, in bp of the average: 10000 when not known. */
    public function ageBp(?int $age): int
    {
        $table = $this->config['age_step_bp'] ?? [];
        if ($age === null || ! $table) {
            return 10000;
        }
        ksort($table);
        foreach ($table as $upTo => $bp) {
            if ($age <= $upTo) {
                return (int) $bp;
            }
        }

        return (int) end($table);
    }

    /**
     * A player trained without a break for $sessions sessions: the points he gains, slower past his potential [X16].
     * For sim:training and the tests; the game moves one session at a time (App\Training\Training).
     */
    public function run(int $overall, int $potential, int $sessions, string $key, int $progress = 0, ?int $age = null): int
    {
        $scale = (int) $this->config['progress_scale'];
        $gained = 0;
        for ($s = 0; $s < $sessions && $overall + $gained < $this->ceiling(); $s++) {
            $progress += $this->step($overall + $gained, "{$key}:{$s}", $potential, $age);
            if ($progress >= $scale) {
                $gained++;
                $progress = 0;
            }
        }

        return $gained;
    }
}
