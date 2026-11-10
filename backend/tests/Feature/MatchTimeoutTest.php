<?php

namespace Tests\Feature;

use App\Events\MatchTimeout;
use App\League\MatchOrders;
use App\League\MatchRunner;
use App\League\Momentum;
use App\Models\User;
use App\Simulator\CoachWindows;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 50 M14, M15] The coach's one timeout holds play for everyone and opens the changes; the momentum wave. */
class MatchTimeoutTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_one_timeout_holds_the_next_minute_and_opens_the_changes(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $mine = $league['my_club_id'];
        $fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        $side = $fixture->home_id === $mine ? 'home' : 'away';
        Carbon::setTestNow(Carbon::parse($fixture->scheduled_at, 'UTC'));
        MatchRunner::step();
        $match = DB::table('matches')->where('fixture_id', $fixture->id)->first();
        // Play into the open, outside a window.
        while (true) {
            MatchOrders::watching($match->id, $side);
            Carbon::setTestNow(GameClock::now()->addMilliseconds(500));
            MatchRunner::step();
            $state = Cache::get("league-match:{$match->id}")['state'];
            if (($state['out']['minute'][0] ?? 0) >= 5 && ! CoachWindows::open($state)) {
                break;
            }
        }
        $sub = fn () => $this->postJson("/api/v1/matches/{$match->id}/actions", ['type' => 'tactics', 'tactics' => ['pressing' => 80], 'idempotency_key' => uniqid('k', true)]);
        $sub()->assertStatus(409);

        Event::fake([MatchTimeout::class]);
        $tick = (int) Cache::get("league-match:{$match->id}")['state']['tick'];
        $until = $this->postJson("/api/v1/matches/{$match->id}/timeout")->assertOk()->assertJsonPath('timeout.side', $side)->json('timeout.until');
        Event::assertDispatched(MatchTimeout::class, fn ($e) => $e->matchId === $match->id && $e->timeout['until'] === $until);
        $this->assertGreaterThanOrEqual(GameClock::nowMs() + 1000 * (int) config('game.match.timeout_seconds'), $until);
        // Once a match; the changes open while it holds.
        $this->postJson("/api/v1/matches/{$match->id}/timeout")->assertConflict();
        $sub()->assertStatus(202);
        // No minute is played before it ends; the next one after.
        Carbon::setTestNow(Carbon::createFromTimestampMs($until - 2000));
        MatchRunner::step();
        $this->assertSame($tick, (int) Cache::get("league-match:{$match->id}")['state']['tick']);
        Carbon::setTestNow(Carbon::createFromTimestampMs($until + 10));
        MatchRunner::step();
        $this->assertGreaterThan($tick, (int) Cache::get("league-match:{$match->id}")['state']['tick']);
        $this->getJson("/api/v1/matches/{$match->id}")->assertJsonPath('timeouts.0.side', $side)->assertJsonPath('timeouts.0.tick', $tick);
        // The minutes carry the momentum wave.
        $this->assertNotNull(Cache::get("league-match:{$match->id}")['recent'][0]['momentum'] ?? null);
    }

    public function test_the_momentum_wave_is_the_home_share_of_the_last_minutes(): void
    {
        $this->assertSame(['now' => 0, 'home_pct' => 50], Momentum::wave([]));
        $this->assertSame(['now' => -1, 'home_pct' => 75], Momentum::wave([2, 1, 0, -1]));
        // Only the last ten minutes count.
        $this->assertSame(['now' => 1, 'home_pct' => 100], Momentum::wave([...array_fill(0, 20, -2), ...array_fill(0, 10, 1)]));
    }
}
