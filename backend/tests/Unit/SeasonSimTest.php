<?php

namespace Tests\Unit;

use App\Economy\Money;
use App\Economy\SeasonSim;
use Tests\TestCase;

/** The economy's season simulation [Sprint 23 B5]: the same rules, the books add up, and the scenarios bite. */
class SeasonSimTest extends TestCase
{
    private function clubs(): array
    {
        $clubs = [];
        foreach (range(1, 6) as $i) {
            $clubs[$i] = ['name' => "C{$i}", 'strength' => 9000 - $i * 300, 'players' => array_fill(0, 20, 4_000_000 - $i * 400_000)];
        }

        return $clubs;
    }

    /** The stronger side (the lower id) wins 2-0, at home or away. */
    private function play(): callable
    {
        return fn (int $home, int $away) => $home < $away ? ['home' => 2, 'away' => 0] : ['home' => 0, 'away' => 2];
    }

    public function test_the_books_add_up_and_the_season_meets_the_targets(): void
    {
        $sim = new SeasonSim(Money::fromConfig(), config('game.economy'));
        $season = $sim->run($this->clubs(), 3_000_000, $this->play());
        $this->assertSame(10, $season['rounds']);
        foreach ($season['clubs'] as $b) {
            $this->assertSame(3_000_000 + $b['income'] - $b['wages'] - $b['penalties'], $b['balance']);
        }
        // The champion earns more than the last.
        $this->assertGreaterThan($season['clubs'][6]['income'], $season['clubs'][1]['income']);
        $this->assertTrue(SeasonSim::summary($season, config('game.economy.sim_targets'))['ok']);
    }

    public function test_a_spendthrift_pays_in_forced_sales_and_colluders_move_no_more_than_the_cap(): void
    {
        $sim = new SeasonSim(Money::fromConfig(), config('game.economy'));
        $sane = $sim->run($this->clubs(), 3_000_000, $this->play());
        $spent = $sim->run($this->clubs(), 3_000_000, $this->play(), ['spender' => 6]);
        $this->assertGreaterThan(0, $spent['clubs'][6]['bought']);
        $this->assertLessThan($sane['clubs'][6]['balance'], $spent['clubs'][6]['balance']);

        $pair = $sim->run($this->clubs(), 3_000_000, $this->play(), ['colluders' => [6, 5]]);
        $this->assertSame(750_000, $pair['moved']);
        $this->assertSame($sane['clubs'][5]['balance'] + 750_000, $pair['clubs'][5]['balance']);
    }

    public function test_a_dealer_makes_no_more_than_the_seasons_profit_room(): void
    {
        // [Sprint 23] 250%, buy-train-sell, the discounts: all of it within sale_profit_bp_per_season of the scale.
        $cfg = config('game.economy');
        $sim = new SeasonSim(Money::fromConfig(), $cfg);
        $sane = $sim->run($this->clubs(), 3_000_000, $this->play());
        $dealer = $sim->run($this->clubs(), 3_000_000, $this->play(), ['dealer' => 3]);
        $room = intdiv($sane['scale'] * $cfg['sale_profit_bp_per_season'], 10000);
        $this->assertGreaterThan(0, $room);
        $this->assertSame($sane['clubs'][3]['balance'] + $room, $dealer['clubs'][3]['balance']);
    }

    public function test_a_deep_debt_sells_the_dearest_players_but_keeps_a_squad(): void
    {
        $cfg = config('game.economy');
        $cfg['wages_bp_per_season'] = 5000;    // wages far above any income
        $season = (new SeasonSim(new Money($cfg), $cfg))->run($this->clubs(), 0, $this->play());
        $this->assertGreaterThan(0, array_sum(array_column($season['clubs'], 'sold')));
        foreach ($season['size'] as $size) {
            $this->assertGreaterThanOrEqual($cfg['min_squad'], $size);
        }
        $this->assertFalse(SeasonSim::summary($season, $cfg['sim_targets'])['ok']);
    }
}
