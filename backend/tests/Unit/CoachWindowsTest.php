<?php

namespace Tests\Unit;

use App\Simulator\CoachWindows;
use PHPUnit\Framework\TestCase;

/** The coach's windows [X42]: play stops after minutes 15, 30, 60 and 75, and only then may a coach change. */
class CoachWindowsTest extends TestCase
{
    private const TIMING = ['halftime_seconds' => 30, 'extra_time_break_seconds' => 10, 'windows' => [15, 30, 60, 75], 'window_seconds' => 30];

    private static function tick(int $minute, int $added = 0, int $period = 1, array $events = []): array
    {
        return ['minute' => [$minute, $added], 'period' => $period, 'events' => $events];
    }

    private static function state(array $out, array $timing = self::TIMING): array
    {
        return ['cfg' => ['match' => $timing], 'out' => $out, 'finished' => false];
    }

    public function test_the_match_stops_after_each_window_minute_and_at_half_time(): void
    {
        foreach ([15, 30, 60, 75] as $m) {
            $this->assertSame(30000, CoachWindows::pauseMs(self::tick($m, 0, $m > 45 ? 2 : 1), self::TIMING), "minute {$m}");
        }
        foreach ([1, 14, 16, 45, 59, 89, 90] as $m) {
            $this->assertSame(0, CoachWindows::pauseMs(self::tick($m), self::TIMING), "minute {$m}");
        }
        // Not a minute added on, nor extra time.
        $this->assertSame(0, CoachWindows::pauseMs(self::tick(30, 1), self::TIMING));
        $this->assertSame(0, CoachWindows::pauseMs(self::tick(105, 0, 3), ['windows' => [105]] + self::TIMING));
        $this->assertSame(30000, CoachWindows::pauseMs(self::tick(45, 2, 1, [['type' => 'period', 'name' => 'halftime']]), self::TIMING));
    }

    public function test_a_coach_changes_before_kick_off_and_in_the_breaks_only(): void
    {
        $this->assertTrue(CoachWindows::open(['cfg' => ['match' => self::TIMING], 'finished' => false]));
        $this->assertTrue(CoachWindows::open(self::state(self::tick(15))));
        $this->assertFalse(CoachWindows::open(self::state(self::tick(16))));
        $this->assertTrue(CoachWindows::open(self::state(self::tick(45, 3, 1, [['type' => 'period', 'name' => 'halftime']]))));
        $this->assertFalse(CoachWindows::open(['finished' => true] + self::state(self::tick(75))));
        // A match made before the windows: at any minute, as it was.
        $this->assertTrue(CoachWindows::open(self::state(self::tick(16), ['halftime_seconds' => 30])));
        $this->assertSame(0, CoachWindows::pauseMs(self::tick(15), ['halftime_seconds' => 30]));
    }
}
