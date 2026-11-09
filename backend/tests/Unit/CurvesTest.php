<?php

namespace Tests\Unit;

use App\Engine\Curves;
use PHPUnit\Framework\TestCase;

/** [Sprint 49] The match's S-curves in integers: close to the real ones, symmetric, and bounded. */
class CurvesTest extends TestCase
{
    public function test_tanh_follows_the_real_curve_within_a_tenth_of_a_per_cent(): void
    {
        foreach (range(-40000, 40000, 137) as $x) {
            $this->assertEqualsWithDelta((int) round(tanh($x / 10000) * 10000), Curves::tanh($x), 10, "x = {$x}");
            $this->assertSame(-Curves::tanh($x), Curves::tanh(-$x));
            $this->assertIsInt(Curves::tanh($x));
        }
        $this->assertSame(0, Curves::tanh(0));
        $this->assertLessThanOrEqual(10000, Curves::tanh(PHP_INT_MAX >> 20));
    }

    public function test_the_logistic_is_a_half_at_zero_and_stays_between_nothing_and_all(): void
    {
        $this->assertSame(5000, Curves::logistic(0));
        foreach (range(-60000, 60000, 251) as $x) {
            $this->assertEqualsWithDelta((int) round(10000 / (1 + exp(-$x / 10000))), Curves::logistic($x), 10, "x = {$x}");
            $this->assertGreaterThanOrEqual(0, Curves::logistic($x));
            $this->assertLessThanOrEqual(10000, Curves::logistic($x));
        }
    }

    public function test_the_share_of_the_ball_is_even_for_equals_and_never_all_of_it(): void
    {
        $this->assertSame(5000, Curves::share(0, 12000));
        $this->assertSame(10000 - Curves::share(3000, 12000), Curves::share(-3000, 12000));
        $this->assertGreaterThan(Curves::share(1000, 12000), Curves::share(2000, 12000));
        $this->assertLessThan(10000, Curves::share(20000, 12000));
    }
}
