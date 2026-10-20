<?php

namespace Tests\Unit;

use App\Simulator\Golden;
use Tests\TestCase;

class EngineVersionTest extends TestCase
{
    /** The golden recording is for the current engine (record again with sim:golden --write after a change). */
    public function test_the_golden_recording_belongs_to_the_current_engine_version(): void
    {
        $golden = json_decode(file_get_contents(base_path(Golden::FILE)), true);

        $this->assertSame(config('game.engine.version'), $golden['engine_version']);
    }
}
