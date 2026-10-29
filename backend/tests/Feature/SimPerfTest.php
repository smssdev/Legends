<?php

namespace Tests\Feature;

use App\Console\Commands\SimPerf;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** sim:perf times simulateTick and fails above the per-minute budget [Sprint 21 E8.1]. */
class SimPerfTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_it_passes_within_the_budget_and_fails_above_it(): void
    {
        $this->template(2, full: true);

        $this->artisan('sim:perf', ['--matches' => 2])->expectsOutputToContain('Within the budget.')->assertSuccessful();
        // No minute takes no time at all: a budget of zero always fails.
        $this->artisan('sim:perf', ['--matches' => 1, '--budget' => 0])->assertFailed();
        $this->assertSame(20, config('game.perf.tick_budget_ms'));
    }

    public function test_percentiles_are_nearest_rank(): void
    {
        $times = array_map(fn ($i) => (float) $i, range(1, 100));
        $this->assertSame(50.0, SimPerf::pct($times, 50));
        $this->assertSame(99.0, SimPerf::pct($times, 99));
        $this->assertSame(0.0, SimPerf::pct([], 95));
    }
}
