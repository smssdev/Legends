<?php

namespace Tests\Feature;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class ClockTravelTest extends TestCase
{
    private string $file;

    protected function setUp(): void
    {
        parent::setUp();
        $this->file = sys_get_temp_dir().'/legends-clock-'.getmypid().'.json';
        GameClock::useFile($this->file);
        Carbon::setTestNow('2026-10-21 10:00:00');
    }

    protected function tearDown(): void
    {
        @unlink($this->file);
        GameClock::useFile(null);
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_travel_moves_the_game_time_and_reset_brings_it_back(): void
    {
        $this->artisan('clock:travel', ['by' => '+8h'])->assertSuccessful();
        $this->assertSame('2026-10-21 18:00:00', GameClock::now()->format('Y-m-d H:i:s'));

        $this->artisan('clock:travel', ['by' => '-30m'])->assertSuccessful();
        $this->assertSame('2026-10-21 17:30:00', GameClock::now()->format('Y-m-d H:i:s'));

        $this->artisan('clock:travel', ['by' => '+2d'])->assertSuccessful();
        $this->assertSame('2026-10-23 17:30:00', GameClock::now()->format('Y-m-d H:i:s'));

        $this->artisan('clock:travel', ['by' => 'reset'])->assertSuccessful();
        $this->assertSame('2026-10-21 10:00:00', GameClock::now()->format('Y-m-d H:i:s'));
        $this->assertFileDoesNotExist($this->file);
    }

    public function test_another_process_sees_the_same_game_time(): void
    {
        // The queue worker and the scheduler read the same file the command wrote.
        file_put_contents($this->file, json_encode(['offset' => 3600]));
        touch($this->file, time() + 5);
        $this->assertSame(3600, GameClock::offset());
        $this->assertSame('2026-10-21 11:00:00', GameClock::now()->format('Y-m-d H:i:s'));
    }

    public function test_a_wrong_duration_is_refused(): void
    {
        $this->artisan('clock:travel', ['by' => 'tomorrow'])->assertExitCode(2);
        $this->assertSame(0, GameClock::offset());
    }

    public function test_it_refuses_to_run_in_production_and_production_ignores_any_offset(): void
    {
        GameClock::setOffset(8 * 3600);
        $this->app['env'] = 'production';

        $this->artisan('clock:travel', ['by' => '+8h'])->assertFailed();
        $this->assertSame(0, GameClock::offset());
        $this->assertSame('2026-10-21 10:00:00', GameClock::now()->format('Y-m-d H:i:s'));
    }
}
