<?php

namespace Tests\Unit;

use App\Engine\Ability;
use PHPUnit\Framework\TestCase;

/**
 * [Sprint 39 E1, E2] The owner's simulation file: the fatigue lines (full from 90%, 5% to 10% less from 80%, up to 15%
 * less from 75%, a sharp drop to a quarter less under 75%) and the out-of-position penalty (30% one line away, 50% two).
 */
class FatigueTest extends TestCase
{
    public function test_the_bands_of_fitness(): void
    {
        $this->assertSame(10000, Ability::fitness(10000));
        $this->assertSame(10000, Ability::fitness(9000));
        $this->assertSame(9499, Ability::fitness(8999));
        $this->assertSame(9000, Ability::fitness(8000));
        $this->assertSame(8500, Ability::fitness(7500));
        // Under 75%: falling to a quarter less at 50% and under.
        $this->assertLessThan(8500, Ability::fitness(7499));
        $this->assertSame(7500, Ability::fitness(5000));
        $this->assertSame(7500, Ability::fitness(0));
        foreach (range(0, 10000, 250) as $f) {
            $this->assertGreaterThanOrEqual(Ability::fitness(max(0, $f - 250)), Ability::fitness($f), (string) $f);
        }
    }

    public function test_out_of_position_costs_by_the_lines_between(): void
    {
        $at = fn (string $pos, string $line, string $slot, string $alt = '') => Ability::position(['pos' => $pos, 'line' => $line, 'slot_line' => $slot, 'alt' => $alt]);
        $this->assertSame(10000, $at('CB', 'def', 'def'));
        $this->assertSame(7000, $at('CB', 'def', 'mid'));
        $this->assertSame(7000, $at('CM', 'mid', 'att'));
        $this->assertSame(5000, $at('CB', 'def', 'att'));
        $this->assertSame(4000, $at('ST', 'att', 'gk'));
        // A winger on the flank of midfield, and a second position in the line, are in place.
        $this->assertSame(10000, $at('LW', 'att', 'mid'));
        $this->assertSame(10000, $at('CDM', 'mid', 'def', 'CB'));
    }
}
