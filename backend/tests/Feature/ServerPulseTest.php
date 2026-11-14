<?php

namespace Tests\Feature;

use App\Admin\ServerPulse;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/** [Sprint 66 B3] The server's pulse in the admin panel: the live answer's median and 95%, the queue, Reverb. */
class ServerPulseTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_percentiles_by_nearest_rank(): void
    {
        $this->assertNull(ServerPulse::percentile([], 50));
        $sorted = range(1, 100);
        $this->assertSame([50, 95, 100, 1], [ServerPulse::percentile($sorted, 50), ServerPulse::percentile($sorted, 95), ServerPulse::percentile($sorted, 100), ServerPulse::percentile([1], 95)]);
    }

    public function test_the_last_five_minutes_count_and_older_ones_leave(): void
    {
        Carbon::setTestNow('2026-11-15 10:00:00');
        foreach ([10, 20, 30, 40] as $ms) {
            ServerPulse::record($ms);
        }
        Carbon::setTestNow('2026-11-15 10:03:00');
        ServerPulse::record(500);
        $this->assertSame(['samples' => 5, 'p50_ms' => 30, 'p95_ms' => 500], ServerPulse::read()['live']);
        Carbon::setTestNow('2026-11-15 10:06:00');
        $this->assertSame(['samples' => 1, 'p50_ms' => 500, 'p95_ms' => 500], ServerPulse::read()['live']);
    }

    public function test_the_admin_reads_it_and_others_cannot(): void
    {
        ServerPulse::record(42);
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs(User::factory()->create())->getJson('/api/v1/admin/server')->assertForbidden();
        $pulse = $this->actingAs(User::factory()->create(['role' => 'admin']))->getJson('/api/v1/admin/server')->assertOk()->json();
        $this->assertSame(1, $pulse['live']['samples']);
        $this->assertSame(42, $pulse['live']['p95_ms']);
        // No Reverb in the tests (broadcasting to the log): said as null, not an error.
        $this->assertNull($pulse['reverb_connections']);
        $this->assertIsInt($pulse['queue']);
    }
}
