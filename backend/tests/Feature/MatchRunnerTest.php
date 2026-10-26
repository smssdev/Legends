<?php

namespace Tests\Feature;

use App\Events\MatchMinute;
use App\League\MatchReplay;
use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The live runner [Sprint 18, PLAN 2.12]. */
class MatchRunnerTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private object $fixture;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        // A development league: a round every minute after one minute of preparation.
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
        $mine = $this->league['my_club_id'];
        $this->fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    /** Move the clock and run one step of the runner, as matches:run does every 200 ms. */
    private function step(int $ms = 0): void
    {
        if ($ms) {
            Carbon::setTestNow(GameClock::now()->addMilliseconds($ms));
        }
        MatchRunner::step();
    }

    private function kickOff(): object
    {
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC'));
        $this->step();

        return DB::table('matches')->where('fixture_id', $this->fixture->id)->first();
    }

    public function test_a_development_match_starts_by_itself_plays_live_and_ends_in_about_eight_minutes(): void
    {
        Event::fake([MatchMinute::class]);
        $match = $this->kickOff();
        $this->assertSame(['live', 'live'], [$match->mode, $match->status]);
        $this->assertSame('live', DB::table('fixtures')->where('id', $this->fixture->id)->value('status'));

        $start = GameClock::now()->copy();
        $seen = 0;
        while (DB::table('matches')->where('id', $match->id)->value('status') === 'live' && $seen < 2000) {
            $this->step(500);
            $seen++;
            if ($seen === 40) {
                // Followed live: the viewer gets the minutes made so far, with their frames.
                $live = $this->getJson("/api/v1/matches/{$match->id}/live?since=0")->assertOk()->json();
                $this->assertTrue($live['started']);
                $this->assertNotEmpty($live['ticks']);
                $this->assertArrayHasKey('frames', $live['ticks'][0]);
            }
        }
        $minutes = $start->diffInSeconds(GameClock::now()) / 60;
        // [X41] Two halves of about three and a half minutes and the break.
        $this->assertGreaterThan(5, $minutes);
        $this->assertLessThan(11, $minutes);

        $done = DB::table('matches')->where('id', $match->id)->first();
        $this->assertSame('finished', $done->status);
        $fixture = DB::table('fixtures')->where('id', $this->fixture->id)->first();
        $this->assertSame(['finished', $done->home_goals, $done->away_goals], [$fixture->status, $fixture->home_goals, $fixture->away_goals]);
        $this->assertGreaterThan(50, DB::table('match_events')->where('match_id', $match->id)->count());
        $this->assertSame(2, DB::table('match_stats')->where('match_id', $match->id)->count());
        Event::assertDispatched(MatchMinute::class, fn ($e) => $e->matchId === $match->id);
        // The table counts it (a development league starts a round every minute, so the next one may be over too).
        $table = collect($this->getJson("/api/v1/leagues/{$this->league['id']}/standings")->json('table'));
        $this->assertGreaterThanOrEqual(1, $table->firstWhere('id', $this->fixture->home_id)['played']);
    }

    public function test_a_killed_runner_resumes_and_the_match_ends_as_it_would_have(): void
    {
        $match = $this->kickOff();
        // Play to about minute 30, then the runner dies and its cache with it.
        while ((int) DB::table('matches')->where('id', $match->id)->value('tick') < 30) {
            $this->step(400);
        }
        Cache::flush();
        Carbon::setTestNow(GameClock::now()->addMinutes(3));
        while (DB::table('matches')->where('id', $match->id)->value('status') === 'live') {
            $this->step(400);
        }
        $done = DB::table('matches')->where('id', $match->id)->first();
        // What the same seed, starting state and orders (the computer's for the bot) give with no interruption.
        [$expected] = MatchReplay::run($done);
        $this->assertSame($expected['score'], ['home' => $done->home_goals, 'away' => $done->away_goals]);
        $this->assertSame($expected['tick'], $done->tick);
        $goals = DB::table('match_events')->where('match_id', $match->id)->where('type', 'goal')->count();
        $this->assertSame($expected['score']['home'] + $expected['score']['away'], $goals);
    }

    public function test_a_stopped_runner_with_its_cache_goes_on_live_and_not_in_one_burst(): void
    {
        $match = $this->kickOff();
        while ((int) DB::table('matches')->where('id', $match->id)->value('tick') < 30) {
            $this->step(400);
        }
        $tick = (int) DB::table('matches')->where('id', $match->id)->value('tick');
        // Stopped for an hour, the cache kept.
        $this->step(3_600_000);
        // Only what is due in the next moment, as a normal step.
        $this->assertLessThanOrEqual($tick + 4, (int) DB::table('matches')->where('id', $match->id)->value('tick'));
        $this->assertSame('live', DB::table('matches')->where('id', $match->id)->value('status'));
    }

    public function test_only_one_runner_plays_at_a_time(): void
    {
        $this->assertTrue(MatchRunner::claim('first'));
        $this->assertTrue(MatchRunner::claim('first'));
        $this->assertFalse(MatchRunner::claim('second'));
        $this->artisan('matches:run --once')->assertFailed();
        // The first one stops (or dies: its claim runs out in seconds); the next one takes over.
        MatchRunner::release('first');
        $this->artisan('matches:run --once')->assertSuccessful();
        Cache::forget('matches-runner');
        Carbon::setTestNow(GameClock::now()->addSeconds(5));
        $this->assertTrue(MatchRunner::claim('third'));
        Carbon::setTestNow(GameClock::now()->addSeconds(11));
        $this->assertTrue(MatchRunner::claim('fourth'));
    }

    public function test_the_broadcast_never_carries_hidden_tactics(): void
    {
        Event::fake([MatchMinute::class]);
        $this->actingAs($this->owner)->putJson("/api/v1/leagues/{$this->league['id']}/team/tactics", ['pressing' => 93, 'tempo' => 91, 'style' => 87])->assertOk();
        $match = $this->kickOff();
        for ($i = 0; $i < 60; $i++) {
            $this->step(500);
        }
        $payloads = Event::dispatched(MatchMinute::class)->map(fn ($e) => json_encode($e[0]->broadcastWith()))->implode("\n");
        $this->assertNotEmpty($payloads);
        foreach (['pressing', 'tempo', 'style', 'tactics', 'debug', '"att":', 'marking'] as $hidden) {
            $this->assertStringNotContainsString($hidden, $payloads, $hidden);
        }
        // The viewer's endpoint: the coach sees his own tactics; another member of the league sees none.
        $this->assertStringContainsString('"pressing":93', json_encode($this->getJson("/api/v1/matches/{$match->id}/live?since=0")->json()));
        $member = $this->approvedCoach($this->owner, $this->league);
        $free = DB::table('clubs')->where('league_id', $this->league['id'])->whereNull('user_id')
            ->whereNotIn('id', [$this->fixture->home_id, $this->fixture->away_id])->value('id');
        $this->actingAs($member)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$free}/claim")->assertCreated();
        $seen = json_encode($this->getJson("/api/v1/matches/{$match->id}/live?since=0")->json()).json_encode($this->getJson("/api/v1/matches/{$match->id}")->json());
        foreach (['pressing', 'tempo', '"style"'] as $hidden) {
            $this->assertStringNotContainsString($hidden, $seen, $hidden);
        }
        $this->actingAs(User::factory()->create())->getJson("/api/v1/matches/{$match->id}/live")->assertNotFound();
    }

    public function test_bot_against_bot_is_played_at_once_and_shown_at_its_natural_end(): void
    {
        $bots = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)->where('id', '!=', $this->fixture->id)->first();
        Carbon::setTestNow(Carbon::parse($bots->scheduled_at, 'UTC'));
        $this->step();
        $match = DB::table('matches')->where('fixture_id', $bots->id)->first();
        $this->assertSame(['instant', 'done'], [$match->mode, $match->status]);
        $this->assertSame('live', DB::table('fixtures')->where('id', $bots->id)->value('status'));
        $this->assertGreaterThan(GameClock::now()->addMinutes(2)->toDateTimeString(), $match->publish_at);
        Carbon::setTestNow(Carbon::parse($match->publish_at, 'UTC'));
        $this->step();
        $this->assertSame('finished', DB::table('fixtures')->where('id', $bots->id)->value('status'));
    }

    public function test_a_long_missed_match_is_simulated_at_once_and_a_short_one_starts_late(): void
    {
        // The server was off: 11 minutes after kick-off.
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC')->addMinutes(11));
        $this->step();
        $match = DB::table('matches')->where('fixture_id', $this->fixture->id)->first();
        $this->assertSame('instant', $match->mode);
        $this->assertSame('finished', DB::table('fixtures')->where('id', $this->fixture->id)->value('status'));
    }

    public function test_a_short_delay_starts_live(): void
    {
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC')->addMinutes(8));
        $this->step();
        $match = DB::table('matches')->where('fixture_id', $this->fixture->id)->first();
        $this->assertSame(['live', 'live'], [$match->mode, $match->status]);
        $this->assertGreaterThanOrEqual(GameClock::nowMs(), (int) $match->next_at);
    }

    public function test_the_match_leaves_its_mark_on_the_players(): void
    {
        $club = $this->league['my_club_id'];
        $players = DB::table('players')->where('club_id', $club)->orderBy('id')->pluck('id');
        // One out injured for two more matches, one suspended for one, one tired on the bench.
        DB::table('players')->where('id', $players[17])->update(['injured_matches' => 2]);
        DB::table('players')->where('id', $players[16])->update(['suspended_matches' => 1]);
        DB::table('players')->where('id', $players[15])->update(['fitness' => 50]);
        // Only this match counts: the development league's next rounds (a minute apart, with their own random
        // lengths) could end first and count the injury down twice.
        DB::table('fixtures')->where('id', '!=', $this->fixture->id)->where('scheduled_at', '>', $this->fixture->scheduled_at)
            ->update(['scheduled_at' => Carbon::parse($this->fixture->scheduled_at, 'UTC')->addDay()]);
        $match = $this->kickOff();
        while (DB::table('matches')->where('id', $match->id)->value('status') === 'live') {
            $this->step(2000);
        }
        $after = DB::table('players')->whereIn('id', $players)->get()->keyBy('id');
        $this->assertSame(1, (int) $after[$players[17]]->injured_matches);
        $stats = collect(json_decode(DB::table('match_stats')->where('match_id', $match->id)->where('club_id', $club)->value('players'), true))->keyBy('id');
        foreach ($stats as $id => $s) {
            if ($s['played']) {
                // His match fitness and a little back before the next match [X21].
                $this->assertSame(min(100, $s['fit'] + (int) config('game.matches.played_recovery')), (int) $after[$id]->fitness, "player {$id} ends with his match fitness");
                $this->assertLessThan(100, $s['fit']);
            }
        }
        // A player who did not play gets some back.
        if (! ($stats[$players[15]]['played'] ?? false)) {
            $this->assertSame(80, (int) $after[$players[15]]->fitness);
        }
        $this->assertSame(0, (int) $after[$players[16]]->suspended_matches);
    }
}
