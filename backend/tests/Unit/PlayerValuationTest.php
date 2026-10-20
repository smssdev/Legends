<?php

namespace Tests\Unit;

use App\Data\PlayerValuation;
use App\Data\Potential;
use Tests\TestCase;

class PlayerValuationTest extends TestCase
{
    private function valuation(): PlayerValuation
    {
        return PlayerValuation::fromConfig();
    }

    public function test_the_rating_table_gives_its_values_and_runs_straight_between_them(): void
    {
        $v = $this->valuation();
        // a 26-year-old midfielder with no room to grow: the table's own numbers
        $this->assertSame(500_000, $v->value(70, 26, 'mid', 70));
        $this->assertSame(2_500_000, $v->value(80, 26, 'mid', 80));
        $this->assertSame(1_900_000, $v->value(78, 26, 'mid', 78)); // 1.1M + 3/5 of the way to 2.5M = 1.94M, to the nearest 100,000
    }

    public function test_more_rating_is_always_worth_more(): void
    {
        $v = $this->valuation();
        $last = 0;
        for ($ovr = 40; $ovr <= 99; $ovr++) {
            $value = $v->value($ovr, 26, 'mid', $ovr);
            $this->assertGreaterThanOrEqual($last, $value, "rating $ovr");
            $last = $value;
        }
    }

    public function test_age_line_and_room_to_grow_move_the_value(): void
    {
        $v = $this->valuation();
        $this->assertGreaterThan($v->value(75, 30, 'mid', 75), $v->value(75, 25, 'mid', 75));
        $this->assertGreaterThan($v->value(75, 25, 'mid', 75), $v->value(75, 19, 'mid', 75));
        $this->assertGreaterThan($v->value(75, 33, 'mid', 75), $v->value(75, 31, 'mid', 75));
        $this->assertGreaterThan($v->value(75, 25, 'gk', 75), $v->value(75, 25, 'att', 75));
        $this->assertGreaterThan($v->value(75, 25, 'mid', 75), $v->value(75, 25, 'mid', 82));
    }

    public function test_values_are_whole_rounded_amounts(): void
    {
        $v = $this->valuation();
        $this->assertSame(0, $v->value(52, 22, 'def', 60) % 1_000);
        $this->assertSame(0, $v->value(77, 22, 'att', 85) % 10_000);
        $this->assertSame(0, $v->value(91, 24, 'att', 93) % 100_000);
        $this->assertGreaterThan(0, $v->value(40, 40, 'gk', 40));
    }

    public function test_potential_gives_the_young_room_and_stops_at_99(): void
    {
        $this->assertSame(74, Potential::for(60, 18));
        $this->assertSame(70, Potential::for(60, 21));
        $this->assertSame(84, Potential::for(80, 25));
        $this->assertSame(82, Potential::for(82, 31));
        $this->assertSame(99, Potential::for(92, 19));
        for ($age = 16; $age <= 40; $age++) {
            $this->assertGreaterThanOrEqual(Potential::for(70, $age + 1), Potential::for(70, $age), "age $age");
        }
    }
}
