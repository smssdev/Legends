<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\ClientErrors;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

/** [Sprint 66 B1, W2] The devices' errors: counted by what they are, nothing personal kept, read by the admin, pruned. */
class ClientErrorsTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function report(array $over = []): TestResponse
    {
        return $this->postJson('/api/v1/client-errors', [
            'platform' => 'web',
            'version' => 'glm-abc123',
            'path' => '/leagues/42/match/9001?tab=chat',
            'message' => "TypeError: can't read 'name' of undefined (coach me@example.com, code 98765432)",
            'stack' => "at render (Lineup.vue:12)\nat patch (vue.js:300)",
            ...$over,
        ]);
    }

    public function test_the_same_error_counts_up_on_one_row_with_nothing_personal(): void
    {
        Carbon::setTestNow('2026-11-15 10:00:00');
        $this->report()->assertNoContent();
        Carbon::setTestNow('2026-11-15 10:05:00');
        $this->report(['path' => '/club'])->assertNoContent();

        $rows = DB::table('client_errors')->get();
        $this->assertCount(1, $rows);
        $row = $rows[0];
        $this->assertSame(2, (int) $row->count);
        $this->assertSame('/club', $row->path);
        $this->assertStringNotContainsString('me@example.com', $row->message);
        $this->assertStringNotContainsString('98765432', $row->message);
        $this->assertStringContainsString('[email]', $row->message);
        $this->assertStringContainsString('2026-11-15 10:00:00', (string) $row->first_seen_at);
        $this->assertStringContainsString('2026-11-15 10:05:00', (string) $row->last_seen_at);
        // No column that could name the player.
        $this->assertEqualsCanonicalizing(
            ['id', 'fingerprint', 'platform', 'version', 'path', 'message', 'stack', 'count', 'first_seen_at', 'last_seen_at'],
            array_keys((array) $row),
        );
    }

    public function test_a_signed_in_player_is_not_recorded_either(): void
    {
        $this->actingAs(User::factory()->create(['email' => 'coach@example.com']));
        $this->report(['message' => 'boom'])->assertNoContent();
        $this->assertSame(1, DB::table('client_errors')->count());
        $this->assertStringNotContainsString('coach@example.com', json_encode(DB::table('client_errors')->first()));
    }

    public function test_the_site_reports_without_a_csrf_token(): void
    {
        // From the site, Sanctum treats a request as a session one: the report carries no cookie and no XSRF token.
        $this->withHeader('Referer', config('app.url'))->withHeader('Origin', config('app.url'));
        $this->report()->assertNoContent();
        $this->assertSame(1, DB::table('client_errors')->count());
    }

    public function test_paths_lose_their_ids_and_queries(): void
    {
        $this->report()->assertNoContent();
        $this->assertSame('/leagues/{n}/match/{n}', DB::table('client_errors')->value('path'));
    }

    public function test_a_report_is_checked_and_kept_small(): void
    {
        $this->report(['platform' => 'desktop'])->assertUnprocessable();
        $this->report(['message' => ''])->assertUnprocessable();
        $this->report(['stack' => str_repeat('x', 3000), 'message' => str_repeat('y', 1000)])->assertStatus(413);
        $this->assertSame(0, DB::table('client_errors')->count());
    }

    public function test_a_different_version_or_platform_is_its_own_row(): void
    {
        $this->report()->assertNoContent();
        $this->report(['version' => 'glm-def456'])->assertNoContent();
        $this->report(['platform' => 'android', 'version' => '1.4.0'])->assertNoContent();
        $this->assertSame(3, DB::table('client_errors')->count());
    }

    public function test_the_admin_reads_them_gathered_and_others_cannot(): void
    {
        $this->report()->assertNoContent();
        $this->report()->assertNoContent();
        $this->report(['platform' => 'android', 'version' => '1.4.0', 'message' => 'Null check operator'])->assertNoContent();
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs(User::factory()->create())->getJson('/api/v1/admin/client-errors')->assertForbidden();
        $admin = User::factory()->create(['role' => 'admin']);
        $all = $this->actingAs($admin)->getJson('/api/v1/admin/client-errors')->assertOk()->json('errors');
        $this->assertCount(2, $all);
        $this->assertSame(2, collect($all)->firstWhere('platform', 'web')['count']);
        $android = $this->actingAs($admin)->getJson('/api/v1/admin/client-errors?platform=android')->assertOk()->json('errors');
        $this->assertSame(['Null check operator'], array_column($android, 'message'));
    }

    public function test_an_error_unseen_for_thirty_days_is_pruned(): void
    {
        Carbon::setTestNow('2026-10-01 10:00:00');
        $this->report()->assertNoContent();
        Carbon::setTestNow('2026-10-20 10:00:00');
        $this->report(['message' => 'recent'])->assertNoContent();
        Carbon::setTestNow('2026-11-01 10:00:00');
        $this->artisan('client-errors:prune')->assertSuccessful();
        $this->assertSame(['recent'], DB::table('client_errors')->pluck('message')->all());
        $this->assertSame(0, ClientErrors::prune());
    }
}
