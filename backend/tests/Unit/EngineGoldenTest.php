<?php

namespace Tests\Unit;

use App\Simulator\Golden;
use PHPUnit\Framework\TestCase;

/**
 * The golden matches play minute for minute as recorded (docs/ENGINE.md 9).
 * CI runs this on x86 and on ARM: an integer-only engine gives the same match
 * on both. After an engine change: bump game.engine.version and run
 * `php artisan sim:golden --write`.
 */
class EngineGoldenTest extends TestCase
{
    public function test_the_golden_matches_are_replayed_exactly(): void
    {
        $golden = json_decode(file_get_contents(__DIR__.'/../../'.Golden::FILE), true);

        foreach (Golden::CASES as $i => $case) {
            $this->assertSame($golden['matches'][$i], Golden::play($case, $golden['snapshot']), "Golden match with seed {$case[0]} changed.");
        }
    }
}
