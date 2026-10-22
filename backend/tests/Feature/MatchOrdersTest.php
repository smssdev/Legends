<?php

namespace Tests\Feature;

use App\League\FormationBook;
use App\League\MatchOrders;
use App\League\MatchReplay;
use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Orders during a league match, the assistant, the computer and the replay [Sprint 19, PLAN 2.12]. */
class MatchOrdersTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private object $fixture;

    private string $side;

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
        $this->side = $this->fixture->home_id === $mine ? 'home' : 'away';
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

    /** Play on, the coach's screen following, until minute $tick (or the end). */
    private function playTo(object $match, int $tick, bool $watching = true): void
    {
        while ((int) DB::table('matches')->where('id', $match->id)->value('tick') < $tick && DB::table('matches')->where('id', $match->id)->value('status') === 'live') {
            if ($watching) {
                MatchOrders::watching($match->id, $this->side);
            }
            $this->step(500);
        }
    }

    private function order(object $match, array $body, int $status = 202)
    {
        return $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/actions", $body + ['idempotency_key' => uniqid('k', true)])->assertStatus($status);
    }

    private function myPlayers(object $match): array
    {
        $state = json_decode($match->initial_state, true)['teams'][$this->side]['players'];

        return [array_values(array_filter($state, fn ($p) => $p['on'] && $p['slot_line'] !== 'gk')), array_values(array_filter($state, fn ($p) => ! $p['on'] && $p['line'] !== 'gk'))];
    }

    public function test_the_coachs_orders_go_in_and_the_replay_is_the_live_match_to_the_letter(): void
    {
        $match = $this->kickOff();
        [$on, $bench] = $this->myPlayers($match);
        $this->playTo($match, 20);
        $this->order($match, ['type' => 'tactics', 'tactics' => ['style' => 85, 'pressing' => 80, 'plan' => 'wings']]);
        $this->playTo($match, 35);
        $this->order($match, ['type' => 'sub', 'out' => $on[3]['id'], 'in' => $bench[0]['id']]);
        $this->order($match, ['type' => 'formation', 'formation' => '4-4-2A']);
        // An order that arrives while a minute is being made: it was meant for a minute already made, so it goes in the next.
        $late = DB::table('matches')->where('id', $match->id)->value('tick');
        MatchOrders::give($match->id, $this->side, $this->owner->id, 'late-one', ['type' => 'tactics', 'tactics' => ['tempo' => 90]], (int) $late);
        $this->playTo($match, 200);

        $done = DB::table('matches')->where('id', $match->id)->first();
        $this->assertSame('finished', $done->status);
        $mine = DB::table('match_actions')->where('match_id', $match->id)->where('source', 'coach')->get();
        $this->assertCount(4, $mine);
        $this->assertTrue($mine->every(fn ($a) => $a->applied_tick !== null && $a->applied_tick >= $a->target_tick));
        $this->assertGreaterThan($late, DB::table('match_actions')->where('idempotency_key', 'late-one')->value('applied_tick'));

        // The replay: same score, same minutes, the same events one by one.
        [$state, $ticks] = MatchReplay::run($done);
        $this->assertSame(['home' => $done->home_goals, 'away' => $done->away_goals], $state['score']);
        $this->assertSame((int) $done->tick, $state['tick']);
        $replayed = collect($ticks)->flatMap(fn ($t) => collect($t['events'])->map(fn ($e) => $t['tick'].':'.$e['type']))->values()->all();
        $stored = DB::table('match_events')->where('match_id', $match->id)->orderBy('id')->get()->map(fn ($e) => $e->tick.':'.$e->type)->all();
        $this->assertSame($replayed, $stored);
        // The league formation went in with its own slots.
        $this->assertSame('4-4-2A', $state['teams'][$this->side]['formation']);
        $this->assertSame(FormationBook::slots('4-4-2A'), $state['teams'][$this->side]['slots']);
        // The sub really happened.
        $this->assertTrue(collect($ticks)->contains(fn ($t) => collect($t['events'])->contains(fn ($e) => $e['type'] === 'action' && $e['action']['type'] === 'sub' && $e['action']['in'] === $bench[0]['id'])));

        // And the viewer gets it with its frames; another member sees no tactics in it.
        $replay = $this->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->json();
        $this->assertTrue($replay['replayable']);
        $this->assertCount(count($ticks), $replay['ticks']);
        $this->assertArrayHasKey('frames', $replay['ticks'][0]);
    }

    public function test_a_restarted_runner_gives_the_orders_again_at_the_same_minutes(): void
    {
        $match = $this->kickOff();
        [$on, $bench] = $this->myPlayers($match);
        $this->playTo($match, 50);
        $this->order($match, ['type' => 'sub', 'out' => $on[1]['id'], 'in' => $bench[1]['id']]);
        $this->order($match, ['type' => 'tactics', 'tactics' => ['style' => 15, 'tempo' => 20]]);
        $this->playTo($match, 65);
        // The runner dies with its cache; it comes back three minutes later.
        Cache::forget("league-match:{$match->id}");
        Carbon::setTestNow(GameClock::now()->addMinutes(3));
        $this->playTo($match, 200);

        $done = DB::table('matches')->where('id', $match->id)->first();
        [$state] = MatchReplay::run($done);
        $this->assertSame(['home' => $done->home_goals, 'away' => $done->away_goals], $state['score']);
        $this->assertSame(2, DB::table('match_actions')->where('match_id', $match->id)->where('source', 'coach')->count());
        // No order was given twice.
        $this->assertSame(DB::table('match_actions')->where('match_id', $match->id)->count(),
            DB::table('match_actions')->where('match_id', $match->id)->distinct()->count('idempotency_key'));
    }

    public function test_the_assistant_manages_for_an_away_coach_and_the_computer_for_a_bot(): void
    {
        // Tired players come off from minute 60.
        DB::table('players')->whereIn('club_id', [$this->fixture->home_id, $this->fixture->away_id])->update(['fitness' => 72]);
        $match = $this->kickOff();
        $this->playTo($match, 200, watching: false);

        $sources = DB::table('match_actions')->where('match_id', $match->id)->pluck('source', 'side');
        $this->assertSame('assistant', DB::table('match_actions')->where('match_id', $match->id)->where('side', $this->side)->value('source'));
        $this->assertSame('cpu', DB::table('match_actions')->where('match_id', $match->id)->where('side', '!=', $this->side)->value('source'));
        $this->assertCount(2, $sources);
        [$state] = MatchReplay::run(DB::table('matches')->where('id', $match->id)->first());
        $this->assertGreaterThan(0, $state['teams'][$this->side]['subs_used']);
    }

    public function test_a_coach_who_follows_his_match_is_not_overruled_by_the_assistant(): void
    {
        DB::table('players')->where('club_id', $this->league['my_club_id'])->update(['fitness' => 72]);
        $match = $this->kickOff();
        $this->playTo($match, 200);
        $this->assertSame(0, DB::table('match_actions')->where('match_id', $match->id)->where('side', $this->side)->count());
    }

    public function test_only_a_sides_coach_orders_it_and_only_while_it_is_played(): void
    {
        $match = $this->kickOff();
        $this->playTo($match, 5);
        $body = ['type' => 'tactics', 'tactics' => ['style' => 70], 'idempotency_key' => 'same-key'];
        $first = $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/actions", $body)->assertStatus(202)->json();
        $again = $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/actions", $body)->assertOk()->json();
        $this->assertSame($first['target_tick'], $again['target_tick']);
        $this->assertTrue($again['duplicate']);
        $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/actions", ['type' => 'formation', 'formation' => '9-0-1', 'idempotency_key' => 'x'])
            ->assertStatus(422);

        // Another member of the league: he follows, he does not manage.
        $member = $this->approvedCoach($this->owner, $this->league);
        $free = DB::table('clubs')->where('league_id', $this->league['id'])->whereNull('user_id')
            ->whereNotIn('id', [$this->fixture->home_id, $this->fixture->away_id])->value('id');
        $this->actingAs($member)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$free}/claim")->assertCreated();
        $this->actingAs($member)->postJson("/api/v1/matches/{$match->id}/actions", $body + ['idempotency_key' => 'm'])->assertForbidden()
            ->assertJsonPath('message', 'لا تدير أياً من الفريقين في هذه المباراة.');
        $this->actingAs(User::factory()->create())->postJson("/api/v1/matches/{$match->id}/actions", $body)->assertNotFound();

        $this->playTo($match, 200);
        $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/actions", $body + ['idempotency_key' => 'after'])->assertStatus(409);
    }

    public function test_my_live_matches_for_the_switcher(): void
    {
        $match = $this->kickOff();
        $list = $this->actingAs($this->owner)->getJson('/api/v1/matches/live')->assertOk()->json('matches');
        $this->assertSame([$match->id], array_column($list, 'id'));
        $this->assertSame([], $this->actingAs(User::factory()->create())->getJson('/api/v1/matches/live')->json('matches'));
    }

    public function test_a_match_from_an_older_engine_is_shown_from_its_events(): void
    {
        $match = $this->kickOff();
        $this->playTo($match, 200);
        DB::table('matches')->where('id', $match->id)->update(['engine_version' => 1]);
        $replay = $this->actingAs($this->owner)->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->json();
        $this->assertFalse($replay['replayable']);
        $this->assertNull($replay['ticks']);
        $this->assertSame(DB::table('match_events')->where('match_id', $match->id)->count(), count($replay['events']));
    }
}
