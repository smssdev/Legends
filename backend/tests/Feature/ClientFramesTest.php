<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\ClientFrames;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

/** [Sprint 74 P2] The phones' frame counts: added up per screen with nothing personal, read by the admin, pruned. */
class ClientFramesTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function report(array $over = []): TestResponse
    {
        return $this->postJson('/api/v1/client-frames', [
            'platform' => 'android',
            'version' => '2.5.3',
            'tier' => 'low',
            'screens' => [
                ['path' => '/leagues/42/squad?tab=1', 'frames' => 1000, 'late16' => 300, 'late33' => 120],
                ['path' => '/match/9001', 'frames' => 600, 'late16' => 30, 'late33' => 6],
            ],
            ...$over,
        ]);
    }

    public function test_sessions_add_up_per_screen_without_ids_and_the_admin_reads_the_worst_first(): void
    {
        Carbon::setTestNow('2026-11-16 10:00:00');
        $this->report()->assertNoContent();
        // Another session, another league: the same screen once its ids are dropped.
        $this->report(['screens' => [['path' => '/leagues/7/squad', 'frames' => 1000, 'late16' => 100, 'late33' => 80]]])->assertNoContent();

        $rows = DB::table('client_frames')->orderBy('path')->get();
        $this->assertCount(2, $rows);
        $squad = $rows->firstWhere('path', '/leagues/{n}/squad');
        $this->assertSame([2000, 400, 200, 2], [(int) $squad->frames, (int) $squad->late16, (int) $squad->late33, (int) $squad->sessions]);
        $this->assertSame('/match/{n}', $rows->firstWhere('path', '/match/{n}')->path);

        $this->withHeader('Referer', config('app.url'));   // the panel is the site's (a session)
        $this->getJson('/api/v1/admin/client-frames')->assertUnauthorized();
        $this->actingAs(User::factory()->create())->getJson('/api/v1/admin/client-frames')->assertForbidden();
        $this->actingAs(User::factory()->create(['role' => 'admin']))->getJson('/api/v1/admin/client-frames')->assertOk()
            ->assertJsonCount(2, 'screens')
            // 200 of 2000 late: 10.00%, in hundredths of a percent; the worst screen first.
            ->assertJsonPath('screens.0.path', '/leagues/{n}/squad')->assertJsonPath('screens.0.late33_bp', 1000)
            ->assertJsonPath('screens.0.late16_bp', 2000)->assertJsonPath('screens.0.sessions', 2)->assertJsonPath('screens.0.tier', 'low')
            ->assertJsonPath('screens.1.late33_bp', 100);
    }

    public function test_figures_that_cannot_be_are_held_and_a_bad_report_is_refused(): void
    {
        // More late frames than frames, a screen twice, an empty one: held to what can be.
        $this->report(['screens' => [
            ['path' => '/home', 'frames' => 500, 'late16' => 900, 'late33' => 950],
            ['path' => '/home', 'frames' => 500, 'late16' => 0, 'late33' => 0],
            ['path' => '/wallet', 'frames' => 0, 'late16' => 0, 'late33' => 0],
        ]])->assertNoContent();
        $row = DB::table('client_frames')->sole();
        $this->assertSame([500, 500, 500, 1], [(int) $row->frames, (int) $row->late16, (int) $row->late33, (int) $row->sessions]);

        $this->report(['platform' => 'web'])->assertStatus(422);
        $this->report(['tier' => 'ultra'])->assertStatus(422);
        $this->report(['screens' => []])->assertStatus(422);
        $this->report(['screens' => array_fill(0, 21, ['path' => '/x', 'frames' => 1, 'late16' => 0, 'late33' => 0])])->assertStatus(422);
        $this->report(['screens' => [['path' => str_repeat('a', 400), 'frames' => 1, 'late16' => 0, 'late33' => 0],
            ...array_fill(0, 12, ['path' => '/'.str_repeat('b', 400), 'frames' => 1, 'late16' => 0, 'late33' => 0])]])->assertStatus(413);
    }

    public function test_a_screen_with_too_few_frames_is_not_judged_and_old_days_are_pruned(): void
    {
        Carbon::setTestNow('2026-10-01 10:00:00');
        $this->report()->assertNoContent();
        Carbon::setTestNow('2026-11-16 10:00:00');
        $this->report(['screens' => [['path' => '/home', 'frames' => 120, 'late16' => 60, 'late33' => 60]]])->assertNoContent();

        $this->assertSame([], ClientFrames::summary(7));   // the old days are out of the week, the new screen under 300 frames
        $this->artisan('client-errors:prune')->assertSuccessful();
        $this->assertSame(['/home'], DB::table('client_frames')->pluck('path')->all());
    }
}
