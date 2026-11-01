<?php

namespace Tests\Feature;

use App\Ads\RewardVerifier;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 21 E9, Sprint 20 S4] Rewarded ads: our own provider, 30 minutes a verified watch, 5 a task, the same watch once. */
class AdRewardTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function reward(array $body)
    {
        return $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/ads/reward", $body);
    }

    /** A provider that takes "ok-…" tokens and returns them as its reward id. */
    private function provider(): void
    {
        config(['game.ads.enabled' => true]);
        $this->app->instance(RewardVerifier::class, new class implements RewardVerifier
        {
            public function name(): string
            {
                return 'fake';
            }

            public function verify(string $token, int $userId): ?string
            {
                return str_starts_with($token, 'ok-') ? $token : null;
            }
        });
    }

    public function test_switched_off_or_with_no_provider_nothing_is_cut(): void
    {
        config(['game.ads.enabled' => false, 'game.ads.driver' => 'none']);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/stadium", ['section' => 'seats', 'idempotency_key' => 'k1'])->assertOk();
        $this->reward(['item' => 'stadium', 'token' => 'ok-1'])->assertStatus(503);
        $this->postJson('/api/v1/ads/start')->assertStatus(503);
        // Switched on with no provider: every token is refused.
        config(['game.ads.enabled' => true]);
        $this->reward(['item' => 'stadium', 'token' => 'ok-1'])->assertStatus(422);
        $this->assertSame(0, DB::table('ad_rewards')->count());
    }

    public function test_our_own_ads_pay_only_once_watched_to_their_end(): void
    {
        // [Sprint 20 S4] The default provider: the game's own ads, timed on the server.
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/stadium", ['section' => 'seats', 'idempotency_key' => 'k1'])->assertOk()
            ->assertJsonPath('building.ads.enabled', true)->assertJsonPath('building.ads.used', 0)->assertJsonPath('building.ads.max', 5);
        $ends = Carbon::parse(DB::table('stadium_builds')->value('ends_at'), 'UTC');
        // No ad written yet: one of the built-in ones, 30 seconds.
        $watch = $this->postJson('/api/v1/ads/start')->assertCreated()->assertJsonPath('ad.id', null)->assertJsonPath('ad.seconds', 30)->json();
        $this->reward(['item' => 'stadium', 'token' => $watch['token']])->assertStatus(422);   // skipped before its end
        Carbon::setTestNow(Carbon::now()->addSeconds(30));
        $this->reward(['item' => 'stadium', 'token' => $watch['token']])->assertOk()->assertJsonPath('used', 1)
            ->assertJsonPath('ends_at', $ends->copy()->subMinutes(30)->toIso8601ZuluString());
        // The same watch again cuts nothing, and another coach cannot use it.
        $this->reward(['item' => 'stadium', 'token' => $watch['token']])->assertOk()->assertJsonPath('used', 1);
        $this->assertSame(1, DB::table('ad_rewards')->count());

        // The developers' own ad is shown instead, counted, and its link is http(s) only.
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin)->withHeader('Referer', config('app.url'));
        $this->postJson('/api/v1/admin/house-ads', ['title' => 'رعاية', 'body' => 'نص الإعلان', 'cta_url' => 'javascript:alert(1)'])->assertStatus(422);
        $id = $this->postJson('/api/v1/admin/house-ads', ['title' => 'رعاية', 'body' => 'نص الإعلان', 'cta_label' => 'زرنا', 'cta_url' => 'https://example.com', 'seconds' => 15])
            ->assertCreated()->json('ad.id');
        $this->actingAs($this->owner)->postJson('/api/v1/ads/start')->assertCreated()->assertJsonPath('ad.id', $id)->assertJsonPath('ad.seconds', 15);
        $this->actingAs($admin)->getJson('/api/v1/admin/house-ads')->assertOk()->assertJsonPath('ads.0.views', 1);
        $this->patchJson("/api/v1/admin/house-ads/{$id}", ['active' => false])->assertOk()->assertJsonPath('ad.active', false);
        $this->actingAs($this->owner)->postJson('/api/v1/ads/start')->assertCreated()->assertJsonPath('ad.id', null);
        $this->actingAs($admin)->deleteJson("/api/v1/admin/house-ads/{$id}")->assertOk();
        $this->actingAs($this->owner)->getJson('/api/v1/admin/house-ads')->assertForbidden();
    }

    public function test_the_games_own_adsense_account_is_the_default_and_its_ads_txt_is_googles_line(): void
    {
        // [X72] The owner's account in config/game.php, unless the server sets another (the tests turn it off).
        $this->assertStringContainsString("env('ADSENSE_CLIENT', 'ca-pub-9280036306568581')", (string) file_get_contents(config_path('game.php')));
        config(['game.adsense.client' => 'ca-pub-9280036306568581']);
        $this->assertSame("google.com, pub-9280036306568581, DIRECT, f08c47fec0942fa0\n", $this->get('/ads.txt')->assertOk()->getContent());
    }

    public function test_google_adsense_is_off_until_the_account_is_set_then_its_video_is_timed_too(): void
    {
        // [X57] No account (or a wrong one): no ads.txt, nothing in /health, and no Google watch.
        config(['game.adsense.client' => 'pub-123']);
        $this->get('/ads.txt')->assertNotFound();
        $this->getJson('/api/v1/health')->assertOk()->assertJsonPath('adsense', null);
        $this->actingAs($this->owner)->postJson('/api/v1/ads/start', ['provider' => 'adsense'])->assertStatus(503);

        config(['game.adsense.client' => 'ca-pub-1234567890123456', 'game.adsense.slot' => '9876543210', 'game.adsense.rewarded' => true]);
        $this->get('/ads.txt')->assertOk()->assertSee('google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0');
        $this->getJson('/api/v1/health')->assertJsonPath('adsense.client', 'ca-pub-1234567890123456')->assertJsonPath('adsense.slot', '9876543210')
            ->assertJsonPath('adsense.rewarded', true)->assertJsonPath('adsense.test', false);

        // Google's video: no ad of ours, and the reward only after its seconds, once, within the same 5 a task.
        $this->postJson("/api/v1/leagues/{$this->league['id']}/stadium", ['section' => 'seats', 'idempotency_key' => 'k1'])->assertOk();
        $watch = $this->postJson('/api/v1/ads/start', ['provider' => 'adsense'])->assertCreated()->assertJsonPath('ad', null)->json();
        $this->assertSame('adsense', DB::table('ad_watches')->value('provider'));
        $this->reward(['item' => 'stadium', 'token' => $watch['token']])->assertStatus(422);
        Carbon::setTestNow(Carbon::now()->addSeconds(10));
        $this->reward(['item' => 'stadium', 'token' => $watch['token']])->assertOk()->assertJsonPath('used', 1);
        $this->postJson('/api/v1/ads/start', ['provider' => 'other'])->assertStatus(422);
    }

    public function test_each_verified_video_cuts_thirty_minutes_once_and_five_at_most(): void
    {
        $this->provider();
        $this->reward(['item' => 'stadium', 'token' => 'ok-0'])->assertNotFound();
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/stadium", ['section' => 'seats', 'idempotency_key' => 'k1'])->assertOk();
        $ends = Carbon::parse(DB::table('stadium_builds')->value('ends_at'), 'UTC');
        $this->reward(['item' => 'stadium', 'token' => 'bad'])->assertStatus(422);
        $this->reward(['item' => 'stadium', 'token' => 'ok-1'])->assertOk()->assertJsonPath('used', 1)->assertJsonPath('minutes', 30)
            ->assertJsonPath('ends_at', $ends->copy()->subMinutes(30)->toIso8601ZuluString());
        // The same video again (a retry): nothing more is cut.
        $this->reward(['item' => 'stadium', 'token' => 'ok-1'])->assertOk()->assertJsonPath('used', 1);
        foreach (range(2, 5) as $n) {
            $this->reward(['item' => 'stadium', 'token' => "ok-{$n}"])->assertOk()->assertJsonPath('used', $n);
        }
        $this->reward(['item' => 'stadium', 'token' => 'ok-6'])->assertStatus(409);
        $this->assertTrue(Carbon::parse(DB::table('stadium_builds')->value('ends_at'), 'UTC')->eq($ends->copy()->subMinutes(150)));
    }

    public function test_a_training_session_is_never_moved_before_now(): void
    {
        $this->provider();
        $player = DB::table('players')->where('club_id', $this->league['my_club_id'])->value('id');
        $now = GameClock::now();
        DB::table('training_slots')->insert(['club_id' => $this->league['my_club_id'], 'line' => 'mid', 'player_id' => $player, 'sessions' => 0,
            'next_at' => $now->copy()->addMinutes(40), 'created_at' => $now, 'updated_at' => $now]);
        $this->reward(['item' => 'training', 'token' => 'ok-1'])->assertStatus(422);   // which line
        $this->reward(['item' => 'training', 'line' => 'mid', 'token' => 'ok-1'])->assertOk()->assertJsonPath('ends_at', $now->copy()->addMinutes(10)->toIso8601ZuluString());
        $this->reward(['item' => 'training', 'line' => 'mid', 'token' => 'ok-2'])->assertOk()->assertJsonPath('ends_at', $now->toIso8601ZuluString());
        // Another coach cannot cut this club's time: they have no team here.
        $this->actingAs(User::factory()->create())->postJson("/api/v1/leagues/{$this->league['id']}/ads/reward", ['item' => 'training', 'line' => 'mid', 'token' => 'ok-3'])->assertForbidden();
    }
}
