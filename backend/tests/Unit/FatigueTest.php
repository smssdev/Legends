<?php

namespace Tests\Unit;

use App\Engine\Ability;
use PHPUnit\Framework\TestCase;

/** [X21] The fatigue lines: full from 75%, up to a tenth less from 55%, a sharp drop under 55%. */
class FatigueTest extends TestCase
{
    public function test_the_three_bands_of_fitness(): void
    {
        $this->assertSame(10000, Ability::fitness(10000));
        $this->assertSame(10000, Ability::fitness(7500));
        $this->assertSame(9999, Ability::fitness(7499));
        $this->assertSame(9000, Ability::fitness(5500));
        // Under 55%: a step down, then falling.
        $this->assertLessThan(8500, Ability::fitness(5499));
        $this->assertSame(5500, Ability::fitness(0));
        foreach (range(0, 10000, 250) as $f) {
            $this->assertGreaterThanOrEqual(Ability::fitness(max(0, $f - 250)), Ability::fitness($f), (string) $f);
        }
    }
}
