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

/** [Sprint 21 E9] Rewarded videos: off by default, 30 minutes a verified video, 5 a task, the same video once. */
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

    public function test_off_until_the_owner_picks_a_provider(): void
    {
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/stadium", ['section' => 'seats', 'idempotency_key' => 'k1'])->assertOk();
        $this->reward(['item' => 'stadium', 'token' => 'ok-1'])->assertStatus(503);
        // Switched on with no provider chosen: every token is refused.
        config(['game.ads.enabled' => true]);
        $this->reward(['item' => 'stadium', 'token' => 'ok-1'])->assertStatus(422);
        $this->assertSame(0, DB::table('ad_rewards')->count());
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
