<?php

namespace Tests\Feature;

use App\Characters\Mood;
use App\Events\ClubReading;
use App\Events\MatchMinute;
use App\League\LiveDegrade;
use App\League\MatchReplay;
use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The league match screen's server side [Sprint 20]: the commentary, the live readings, the report, and coming back. */
class MatchCommentaryTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private object $fixture;

    private const HIDDEN = ['pressing', 'tempo', '"style"', 'tactics', 'marking', '"trap"', 'الضغط', 'الإيقاع', 'الأسلوب', 'التمركز'];

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
        $mine = $this->league['my_club_id'];
        $this->fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        // The coach plays with extreme tactics: none of it may reach a line, a reading or the report.
        $this->actingAs($this->owner)->putJson("/api/v1/leagues/{$this->league['id']}/team/tactics", ['pressing' => 93, 'tempo' => 91, 'style' => 87])->assertOk();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

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

    private function playTo(int $id, int $tick): void
    {
        while ((int) DB::table('matches')->where('id', $id)->value('tick') < $tick && DB::table('matches')->where('id', $id)->value('status') === 'live') {
            $this->step(400);
        }
    }

    public function test_the_live_match_reads_with_commentary_readings_and_a_report_for_each_coach(): void
    {
        Event::fake([MatchMinute::class, ClubReading::class]);
        $match = $this->kickOff();
        $this->playTo($match->id, 999);
        $mine = $this->league['my_club_id'];
        $side = $this->fixture->home_id === $mine ? 'home' : 'away';

        // Every minute broadcast carries its commentary, the same for both coaches.
        $events = Event::dispatched(MatchMinute::class)->flatMap(fn ($e) => $e[0]->broadcastWith()['events']);
        $told = $events->filter(fn ($e) => in_array($e['type'], ['goal', 'card', 'period'], true));
        $this->assertNotEmpty($told);
        $this->assertTrue($told->every(fn ($e) => isset($e['text']) && $e['text'] !== ''));
        $this->assertNotEmpty(DB::table('match_events')->where('match_id', $match->id)->where('payload', 'like', '%"text"%')->count());
        // And the commentator's line, drawn on the server, goes with every minute [Sprint 35].
        $minutes = Event::dispatched(MatchMinute::class)->map(fn ($e) => $e[0]->broadcastWith());
        $this->assertTrue($minutes->every(fn ($m) => array_key_exists('voice', $m)));
        $goal = $minutes->first(fn ($m) => collect($m['events'])->contains('type', 'goal'));
        if ($goal) {
            $this->assertContains($goal['voice']['line'], ['goal', 'header', 'penalty_goal', 'free_kick_goal']);
        }

        // The assistant spoke to the coach a few times, on his club's own channel only.
        // (A development league plays a round every minute, so the coach's next matches run alongside.)
        $readings = Event::dispatched(ClubReading::class)->map(fn ($e) => $e[0])->filter(fn ($r) => $r->matchId === $match->id)->values();
        $this->assertGreaterThanOrEqual(3, $readings->count());
        $this->assertTrue($readings->every(fn ($r) => $r->clubId === $mine && $r->broadcastOn()->name === "private-club.{$mine}"));
        $this->assertSame($readings->count(), DB::table('match_readings')->where('match_id', $match->id)->count());

        // The report: for the coach, his side's; the rows for both clubs.
        $report = $this->getJson("/api/v1/matches/{$match->id}/report")->assertOk()
            // [Sprint 59 F1] The fields the app reads through MatchCoachReport (openapi.yaml).
            ->assertJsonStructure(['side', 'result', 'score', 'verdict' => ['*' => ['tag', 'text']], 'timeline',
                'reasons' => ['*' => ['title', 'text', 'big']], 'ratings' => ['home' => ['*' => ['team', 'id', 'name', 'rating']], 'away'],
                'stats' => ['home', 'away']])->json();
        $this->assertSame($side, $report['side']);
        $this->assertNotEmpty($report['reasons']);
        $this->assertCount($readings->count(), $report['readings']);
        $this->assertSame(2, DB::table('match_reports')->where('match_id', $match->id)->count());
        // [X62 E10] The shot map: every shot of the match, on the half pitch, its goals the match's goals.
        $shots = collect($report['shots']);
        $this->assertLessThanOrEqual((int) $report['score']['home'] + (int) $report['score']['away'], $shots->where('result', 'goal')->count());
        $this->assertGreaterThanOrEqual($shots->where('result', 'goal')->count(), $shots->count());
        foreach ($shots as $sh) {
            $this->assertTrue($sh['x'] >= 50 && $sh['x'] <= 100 && $sh['y'] >= 0 && $sh['y'] <= 100);
        }
        // And a message tells the coach it is ready [Sprint 22].
        $links = collect($this->getJson('/api/v1/messages')->json('messages'))->where('type', 'match_report')->pluck('link');
        $this->assertContains("/live/{$match->id}/report", $links);
        $text = json_encode([$report, $readings->map->broadcastWith()->all()], JSON_UNESCAPED_UNICODE);
        foreach (self::HIDDEN as $hidden) {
            $this->assertStringNotContainsString($hidden, $text, $hidden);
        }

        // Another member of the league sees the match, not the coaches' reports or readings.
        $member = $this->approvedCoach($this->owner, $this->league);
        $free = DB::table('clubs')->where('league_id', $this->league['id'])->whereNull('user_id')
            ->whereNotIn('id', [$this->fixture->home_id, $this->fixture->away_id])->value('id');
        $this->actingAs($member)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$free}/claim")->assertCreated();
        $this->actingAs($member)->getJson("/api/v1/matches/{$match->id}/report")->assertForbidden()->assertJsonPath('message', 'التقرير لمدربي الفريقين فقط.');
    }

    public function test_watching_a_match_uses_up_no_other_limit(): void
    {
        $match = $this->kickOff();
        $this->playTo($match->id, 3);
        // A coach on two screens polls the minute about four times a second for a while...
        for ($i = 0; $i < 200; $i++) {
            $this->getJson("/api/v1/matches/{$match->id}/live?since=999")->assertOk();
        }
        // ...and his order is still heard (refused for the minute, between two windows [X42], never for a limit),
        // and he opens the match and his league.
        $this->postJson("/api/v1/matches/{$match->id}/actions", ['type' => 'tactics', 'tactics' => ['tempo' => 40], 'idempotency_key' => 'k1'])->assertStatus(409);
        // [Sprint 32 V3] Its kick-off time (UTC) comes with it, for the pitch's light.
        $shown = $this->getJson("/api/v1/matches/{$match->id}")->assertOk();
        $kickoff = $shown->json('kickoff_at');
        // [X76] And each club's kit pattern (none set: plain).
        $this->assertArrayHasKey('pattern', $shown->json('clubs.home'));
        $this->assertMatchesRegularExpression('/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/', $kickoff);
        $this->getJson("/api/v1/leagues/{$this->league['id']}")->assertOk();
    }

    public function test_coming_back_after_a_lost_connection_loses_no_event(): void
    {
        // The catch-up (E8.5), off by default since Sprint 43 C5.
        config(['game.live.catch_up' => true]);
        $match = $this->kickOff();
        $this->playTo($match->id, 50);
        $now = (int) DB::table('matches')->where('id', $match->id)->value('tick');
        [, $all] = MatchReplay::run(DB::table('matches')->where('id', $match->id)->first());
        $expected = fn (int $since, int $until) => collect($all)->filter(fn ($t) => $t['tick'] > $since && $t['tick'] <= $until)
            ->flatMap(fn ($t) => array_map(fn ($e) => $e['type'], $t['events']))->values()->all();

        foreach ([$now - 10, 3] as $since) {
            // 30 seconds away (about 10 minutes of play) comes back whole; a long absence comes back as events.
            $r = $this->getJson("/api/v1/matches/{$match->id}/live?since={$since}")->assertOk()->json();
            $this->assertSame($since !== 3 ? false : true, $r['gap']);
            $got = [...collect($r['missed'])->flatMap(fn ($t) => array_column($t['events'], 'type'))->all(),
                ...collect($r['ticks'])->flatMap(fn ($t) => array_column($t['events'], 'type'))->all()];
            $this->assertSame($expected($since, $r['tick']), $got, "since {$since}");
        }
        // The half-time events are kept in the database, the rest in the cache: both come back.
        $this->assertGreaterThan(0, DB::table('match_events')->where('match_id', $match->id)->count());
    }

    public function test_each_minute_says_how_each_coach_feels_and_the_match_shows_their_looks(): void
    {
        // [Sprint 26 B1, B3] The coach picked his look; the match shows it on his side, and the computer's side has none.
        $this->actingAs($this->owner)->patchJson('/api/v1/auth/me', ['coach_look' => 'C3'])->assertOk();
        Event::fake([MatchMinute::class]);
        $match = $this->kickOff();
        $this->playTo($match->id, 90);
        $sent = Event::dispatched(MatchMinute::class)->map(fn ($e) => $e[0]->broadcastWith())->where('match_id', $match->id)->values();
        $this->assertGreaterThanOrEqual(90, $sent->count());
        $goals = 0;
        foreach ($sent as $p) {
            $this->assertContains($p['moods']['home'], Mood::ALL);
            $this->assertContains($p['moods']['away'], Mood::ALL);
            foreach ($p['events'] as $e) {
                if ($e['type'] === 'goal' && ! collect($p['events'])->contains(fn ($x) => $x['type'] === 'period')) {
                    $this->assertSame('cheer', $p['moods'][$e['team']]);
                    $goals++;
                }
            }
        }
        // The poll carries the same moods.
        $r = $this->getJson("/api/v1/matches/{$match->id}/live?since=45")->assertOk()->json();
        $this->assertArrayHasKey('moods', $r['ticks'][0]);
        $side = $this->fixture->home_id === $this->league['my_club_id'] ? 'home' : 'away';
        $looks = $this->getJson("/api/v1/matches/{$match->id}")->assertOk()->json('coach_looks');
        $this->assertSame(['C3'], array_values($looks));
        $this->assertArrayHasKey($side, $looks);
    }

    public function test_each_minute_carries_its_match_time_and_server_time_built_once_for_everyone(): void
    {
        Event::fake([MatchMinute::class]);
        $match = $this->kickOff();
        $this->playTo($match->id, 50);

        // [E8.3] L1: the match's own clock only grows (stoppage minutes too), and the server made each minute before it starts.
        $sent = Event::dispatched(MatchMinute::class)->map(fn ($e) => $e[0]->broadcastWith())->where('match_id', $match->id)->values();
        $this->assertGreaterThanOrEqual(50, $sent->count());
        foreach ($sent as $i => $p) {
            $this->assertSame(($p['tick'] - 1) * 60_000, $p['match_time']);
            $this->assertIsInt($p['server_ts']);
            $this->assertLessThanOrEqual($p['at'], $p['server_ts']);
            if ($i > 0) {
                $this->assertGreaterThan($sent[$i - 1]['match_time'], $p['match_time']);
            }
        }
        // One payload for the channel: the same bytes whoever receives it, with no side's tactics.
        $e = Event::dispatched(MatchMinute::class)->first()[0];
        $this->assertSame(json_encode($e->broadcastWith()), json_encode($e->broadcastWith()));
        $this->assertSame('private-match.'.$match->id, $e->broadcastOn()->name);
        // The poll gives the same two fields on its minutes.
        $r = $this->getJson("/api/v1/matches/{$match->id}/live?since=45")->assertOk()->json();
        $this->assertSame(($r['ticks'][0]['tick'] - 1) * 60_000, $r['ticks'][0]['match_time']);
        $this->assertArrayHasKey('server_ts', $r['ticks'][0]);
    }

    public function test_a_late_join_jumps_to_now_with_a_summary_and_a_capped_catch_up(): void
    {
        Event::fake([MatchMinute::class, ClubReading::class]);
        $match = $this->kickOff();
        $this->playTo($match->id, 70);
        // [Sprint 43 C5] By default joining late goes on live from now: no summary, nothing missed told.
        $r = $this->getJson("/api/v1/matches/{$match->id}/live?since=0")->assertOk()->json();
        $this->assertSame([true, null, []], [$r['gap'], $r['summary'], $r['missed']]);
        $this->assertNotEmpty($r['ticks']);
        // The catch-up (E8.5) when it is turned on.
        config(['game.live.catch_up' => true, 'game.live.missed_max_minutes' => 5]);
        [, $all] = MatchReplay::run(DB::table('matches')->where('id', $match->id)->first());

        // [E8.5] Joining late (since 0), like a hidden tab or a lost connection: the latest minutes whole, the summary
        // of every missed one (each goal and red card), and the events of no more than the cap [E8.6].
        $r = $this->getJson("/api/v1/matches/{$match->id}/live?since=0")->assertOk()->json();
        $first = $r['ticks'][0]['tick'];
        $this->assertTrue($r['gap']);
        $this->assertSame(['from_tick' => 1, 'to_tick' => $first - 1, 'minutes' => $first - 1], array_slice($r['summary'], 0, 3));
        $goals = collect($all)->filter(fn ($t) => $t['tick'] < $first)->flatMap(fn ($t) => array_filter($t['events'], fn ($e) => $e['type'] === 'goal'))->values();
        $this->assertSame($goals->pluck('team')->all(), array_column($r['summary']['goals'], 'team'));
        // The latest missed minutes that had events, just before the whole ones.
        $latest = collect($all)->filter(fn ($t) => $t['tick'] < $first && $t['events'])->pluck('tick')->slice(-5)->values()->all();
        $this->assertSame($latest, array_column($r['missed'], 'tick'));
        // No gap, no summary.
        $this->assertNull($this->getJson("/api/v1/matches/{$match->id}/live?since=".($first - 1))->json('summary'));
        // A nonsense cursor is read as the start, not an error.
        $this->getJson("/api/v1/matches/{$match->id}/live?since=-5")->assertOk()->assertJsonPath('gap', true);
        // [E8.7] Under load the summary is the first thing given up: still a jump to now, the latest minutes whole.
        LiveDegrade::set(1);
        $r = $this->getJson("/api/v1/matches/{$match->id}/live?since=0")->assertOk()->json();
        $this->assertSame([true, null, []], [$r['gap'], $r['summary'], $r['missed']]);
        $this->assertNotEmpty($r['ticks']);
        LiveDegrade::set(null);
    }

    public function test_catching_up_is_for_members_only_and_rate_limited(): void
    {
        $match = $this->kickOff();
        $this->playTo($match->id, 5);
        // [E8.6] An outsider learns nothing, not even that the match exists.
        $this->actingAs(User::factory()->create())->getJson("/api/v1/matches/{$match->id}/live?since=0")->assertNotFound();
        $this->actingAs(User::factory()->create())->getJson("/api/v1/matches/{$match->id}/replay")->assertNotFound();
        $limits = collect(app('router')->getRoutes()->getRoutes())->filter(fn ($r) => in_array($r->uri(), ['api/v1/matches/{match}/live', 'api/v1/matches/{match}/replay'], true))
            ->map(fn ($r) => collect($r->gatherMiddleware())->first(fn ($m) => str_starts_with($m, 'throttle:')));
        $this->assertCount(2, $limits->filter());
    }
}
