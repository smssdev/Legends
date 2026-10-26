<?php

namespace Tests\Feature;

use App\Events\ClubReading;
use App\Events\MatchMinute;
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
        $report = $this->getJson("/api/v1/matches/{$match->id}/report")->assertOk()->json();
        $this->assertSame($side, $report['side']);
        $this->assertNotEmpty($report['reasons']);
        $this->assertCount($readings->count(), $report['readings']);
        $this->assertSame(2, DB::table('match_reports')->where('match_id', $match->id)->count());
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
        $this->getJson("/api/v1/matches/{$match->id}")->assertOk();
        $this->getJson("/api/v1/leagues/{$this->league['id']}")->assertOk();
    }

    public function test_coming_back_after_a_lost_connection_loses_no_event(): void
    {
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
}
