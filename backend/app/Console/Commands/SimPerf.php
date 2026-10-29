<?php

namespace App\Console\Commands;

use App\Engine\MatchEngine;
use App\Engine\SeededRandom;
use App\Models\MasterClub;
use App\Simulator\MatchFactory;
use App\Support\GameClock;
use Illuminate\Console\Command;

/**
 * The engine's speed [Sprint 21 E8.1]: every MatchMinute of --matches whole matches through
 * MatchEngine::simulateTick, one after another in this one process (PHP runs on one core), timed one by one.
 * Prints p50, p95 and p99 in milliseconds and fails when p99 is above the budget (game.perf.tick_budget_ms).
 * Only the engine is timed: the state is built before the clock starts.
 */
class SimPerf extends Command
{
    protected $signature = 'sim:perf {--matches=50 : Whole matches to play} {--seed=1}
        {--budget= : Milliseconds a minute may take at p99 (default from config)} {--json}';

    protected $description = 'Time simulateTick (p50, p95, p99) and fail above the per-minute budget';

    public function handle(): int
    {
        $clubs = MasterClub::orderByDesc('strength_cp')->orderBy('id')->limit(20)->get()->values();
        if ($clubs->count() < 2) {
            $this->error('No clubs: run the seeders first.');

            return self::FAILURE;
        }
        $budget = (float) ($this->option('budget') ?? config('game.perf.tick_budget_ms'));
        $n = max(1, (int) $this->option('matches'));
        $seed = (int) $this->option('seed');

        $times = [];
        for ($i = 0; $i < $n; $i++) {
            // Every pairing in turn: the offset runs 1..c-1, so a club never meets itself.
            $c = $clubs->count();
            [$home, $away] = [$clubs[$i % $c], $clubs[($i + 1 + intdiv($i, $c) % ($c - 1)) % $c]];
            $state = MatchFactory::make($home, $away, ['seed' => $seed + $i, 'competition' => $i % 5 === 4 ? 'cup' : 'league']);
            for ($guard = 0; ! $state['finished'] && $guard < 200; $guard++) {
                $rng = SeededRandom::forTick($state['seed'], $state['tick'] + 1);
                $t0 = GameClock::stopwatchNs();
                $state = MatchEngine::simulateTick($state, [], $rng);
                $times[] = (GameClock::stopwatchNs() - $t0) / 1e6;
            }
        }
        sort($times);
        $result = [
            'matches' => $n, 'minutes' => count($times),
            'p50_ms' => round(self::pct($times, 50), 3), 'p95_ms' => round(self::pct($times, 95), 3),
            'p99_ms' => round(self::pct($times, 99), 3), 'max_ms' => round(end($times), 3),
            'budget_ms' => $budget,
        ];
        $result['ok'] = $result['p99_ms'] <= $budget;

        if ($this->option('json')) {
            $this->line(json_encode($result));
        } else {
            $this->table(['matches', 'minutes', 'p50', 'p95', 'p99', 'max', 'budget'], [[
                $n, $result['minutes'], $result['p50_ms'], $result['p95_ms'], $result['p99_ms'], $result['max_ms'], $budget,
            ]]);
            $result['ok'] ? $this->info('Within the budget.') : $this->error("p99 {$result['p99_ms']} ms is above the budget of {$budget} ms.");
        }

        return $result['ok'] ? self::SUCCESS : self::FAILURE;
    }

    /** The nearest-rank percentile of sorted times. */
    public static function pct(array $sorted, int $p): float
    {
        if (! $sorted) {
            return 0.0;
        }

        return $sorted[max(0, (int) ceil($p / 100 * count($sorted)) - 1)];
    }
}
