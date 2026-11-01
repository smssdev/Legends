<?php

namespace Tests\Unit;

use App\Simulator\MatchChoreographer;
use PHPUnit\Framework\TestCase;

/** [Sprint 31 D1] The referee and his assistants in every Keyframe: on the pitch, off the ball, on their own lines. */
class OfficialsTest extends TestCase
{
    public function test_the_referee_keeps_off_the_ball_and_the_assistants_on_their_touchlines(): void
    {
        foreach ([[525, 340], [1000, 100], [40, 650], [900, 600], [100, 30], [525, 341]] as [$bx, $by]) {
            [$ref, $far, $near] = MatchChoreographer::officials($bx, $by);
            $this->assertIsInt($ref[0]);
            $this->assertIsInt($ref[1]);
            $this->assertGreaterThanOrEqual(40, $ref[0]);
            $this->assertLessThanOrEqual(1010, $ref[0]);
            $this->assertGreaterThanOrEqual(60, $ref[1]);
            $this->assertLessThanOrEqual(620, $ref[1]);
            $this->assertGreaterThan(80, abs($ref[0] - $bx) + abs($ref[1] - $by), "the referee is not on the ball at {$bx},{$by}");
            $this->assertSame(-14, $far[1]);
            $this->assertSame(694, $near[1]);
            $this->assertGreaterThanOrEqual(525, $far[0]);
            $this->assertLessThanOrEqual(525, $near[0]);
        }
        // Level with the ball in their own half.
        $this->assertSame(800, MatchChoreographer::officials(800, 300)[1][0]);
        $this->assertSame(200, MatchChoreographer::officials(200, 300)[2][0]);
    }
}
