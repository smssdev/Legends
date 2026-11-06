<?php

namespace Tests\Feature;

use App\League\FormationBook;
use App\League\MatchOrders;
use App\League\MatchReplay;
use App\League\MatchRunner;
use App\Models\User;
use App\Notifications\GameUpdateNotice;
use App\Notify\MatchEmail;
use App\Simulator\CoachWindows;
use App\Simulator\Runner;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
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

    /** Play on to the coach's window after minute $minute [X42]: the minute is made, the break before the next. */
    private function playToWindow(object $match, int $minute): void
    {
        while (true) {
            $state = Cache::get("league-match:{$match->id}")['state'] ?? null;
            if ($state && isset($state['out']) && $state['out']['minute'][0] >= $minute && CoachWindows::open($state)) {
                return;
            }
            MatchOrders::watching($match->id, $this->side);
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
        $this->playToWindow($match, 15);
        $this->order($match, ['type' => 'tactics', 'tactics' => ['style' => 85, 'pressing' => 80, 'plan' => 'wings']]);
        $this->playToWindow($match, 30);
        $this->order($match, ['type' => 'sub', 'out' => $on[3]['id'], 'in' => $bench[0]['id']]);
        $this->order($match, ['type' => 'formation', 'formation' => '4-4-2A']);
        // An order that arrives as the window closes: it was meant for a minute already made, so it waits for the next window.
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
        // [X69] A member who coaches neither side watches it in full too, with neither side's tactics.
        $member = $this->memberOutside($this->league, [$this->fixture->home_id, $this->fixture->away_id]);
        $theirs = $this->actingAs($member)->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->json();
        $this->assertCount(count($ticks), $theirs['ticks']);
        $this->assertNull($theirs['ticks'][0]['teams']['home']['tactics'] ?? null);
        $this->assertNull($theirs['ticks'][0]['teams']['away']['tactics'] ?? null);
    }

    public function test_play_stops_after_minute_15_for_the_coachs_window(): void
    {
        $match = $this->kickOff();
        $this->assertSame([15, 30, 60, 75], $this->actingAs($this->owner)->getJson("/api/v1/matches/{$match->id}")->json('timing.windows'));
        $this->playToWindow($match, 15);
        $live = Cache::get("league-match:{$match->id}");
        $window = collect($live['recent'])->last();
        $this->assertSame([15, 0], $window['minute']);
        $this->assertTrue($window['window']);
        // The next minute comes after the scene and the 30 s break.
        $this->assertSame($window['at'] + $window['moment']['ms'] + 30000, $live['next_at']);
        $this->order($match, ['type' => 'tactics', 'tactics' => ['tempo' => 85]]);
        $this->playTo($match, (int) DB::table('matches')->where('id', $match->id)->value('tick') + 2);
        // It went in with the first minute after the window; now the match plays on without changes.
        $this->assertSame($window['tick'] + 1, (int) DB::table('match_actions')->where('match_id', $match->id)->where('source', 'coach')->value('applied_tick'));
        $this->order($match, ['type' => 'tactics', 'tactics' => ['tempo' => 20]], 409);
    }

    public function test_a_restarted_runner_gives_the_orders_again_at_the_same_minutes(): void
    {
        $match = $this->kickOff();
        [$on, $bench] = $this->myPlayers($match);
        $this->playToWindow($match, 60);
        $this->order($match, ['type' => 'sub', 'out' => $on[1]['id'], 'in' => $bench[1]['id']]);
        $this->order($match, ['type' => 'tactics', 'tactics' => ['style' => 15, 'tempo' => 20]]);
        $this->playTo($match, (int) DB::table('matches')->where('id', $match->id)->value('tick') + 6);
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
        // [X42] Between the windows the match plays on: no change.
        $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/actions", $body)->assertStatus(409)
            ->assertJsonPath('message', 'التغيير في فترات التوقف فقط: قبل البداية، وفي الدقائق 15 و30 و45 و60 و75.');
        $this->playToWindow($match, 15);
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

    /** [X78] The scene is kept when the match ends, so it is watched the same after the engine changes. */
    public function test_the_replay_is_kept_and_survives_a_new_engine(): void
    {
        $match = $this->kickOff();
        $this->playTo($match, 200);
        $kept = DB::table('match_replays')->where('match_id', $match->id)->first();
        $this->assertNotNull($kept);
        $this->assertSame((int) config('game.engine.version'), (int) $kept->engine_version);
        $this->assertLessThan(2_000_000, (int) $kept->bytes);
        $before = $this->actingAs($this->owner)->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->json();

        // A new engine: the kept scene, minute for minute.
        DB::table('matches')->where('id', $match->id)->update(['engine_version' => 1]);
        $after = $this->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->json();
        $this->assertTrue($after['replayable']);
        $this->assertSame($before['ticks'], $after['ticks']);

        // Kept once; the command keeps those of this engine that have none, and skips the rest.
        DB::table('matches')->where('id', $match->id)->update(['engine_version' => (int) config('game.engine.version')]);
        DB::table('match_replays')->delete();
        $this->artisan('matches:keep-replays')->assertSuccessful();
        $this->assertTrue(DB::table('match_replays')->where('match_id', $match->id)->exists());
        $count = DB::table('match_replays')->count();
        $this->artisan('matches:keep-replays')->expectsOutput('Kept 0 replays.')->assertSuccessful();
        $this->assertSame($count, DB::table('match_replays')->count());
    }

    /** [X79] The match summary by email: off by default, then for the coach who turned it on with a confirmed email. */
    public function test_the_match_summary_goes_by_email_only_when_asked(): void
    {
        config(['mail.default' => 'smtp']);
        Notification::fake();
        $this->owner->forceFill(['email' => 'coach@example.com', 'email_verified_at' => GameClock::now()])->save();
        $this->actingAs($this->owner)->getJson('/api/v1/notifications')->assertOk()->assertJsonPath('email_match', false)->assertJsonPath('email_ready', true);
        $match = $this->kickOff();
        $this->playTo($match, 200);
        Notification::assertNothingSentTo($this->owner);

        $this->actingAs($this->owner)->putJson('/api/v1/notifications', ['email_match' => true])->assertOk()->assertJsonPath('email_match', true);
        $done = DB::table('matches')->where('id', $match->id)->first();
        $this->assertTrue(MatchEmail::send($this->owner->id, json_decode($done->state, true), $this->side, $match->id, $this->league['id']));
        Notification::assertSentTo($this->owner, GameUpdateNotice::class, fn ($n) => str_ends_with($n->toMail($this->owner)->actionUrl, "/live/{$match->id}/report"));
    }

    public function test_a_match_from_an_older_engine_is_shown_from_its_events(): void
    {
        $match = $this->kickOff();
        $this->playTo($match, 200);
        DB::table('match_replays')->delete();
        DB::table('matches')->where('id', $match->id)->update(['engine_version' => 1]);
        $replay = $this->actingAs($this->owner)->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->json();
        $this->assertFalse($replay['replayable']);
        $this->assertNull($replay['ticks']);
        $this->assertSame(DB::table('match_events')->where('match_id', $match->id)->count(), count($replay['events']));
    }

    /** [UP17] «أنا مستعد»: against the computer, the coach's ready ends the window at once. */
    public function test_the_ready_button_ends_the_window_once_every_coach_is_ready(): void
    {
        $match = $this->kickOff();
        $this->playToWindow($match, 15);
        $poll = $this->actingAs($this->owner)->getJson("/api/v1/matches/{$match->id}/live")->assertOk()->json('pause');
        $this->assertTrue($poll['window']);
        $this->assertSame([], $poll['ready']);
        $before = (int) DB::table('matches')->where('id', $match->id)->value('next_at');
        $ready = $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/ready")->assertOk()->json();
        $this->assertSame([$this->side], $ready['ready']);
        $this->assertLessThan($before, $ready['resume_at']);
        $this->assertSame($ready['resume_at'], (int) DB::table('matches')->where('id', $match->id)->value('next_at'));
        $tick = (int) DB::table('matches')->where('id', $match->id)->value('tick');
        $this->step($ready['resume_at'] - GameClock::nowMs() + 10);
        $this->assertGreaterThan($tick, (int) DB::table('matches')->where('id', $match->id)->value('tick'));
        // Between the windows there is nothing to be ready for.
        $this->actingAs($this->owner)->postJson("/api/v1/matches/{$match->id}/ready")->assertStatus(409);
    }

    /** [UP17] The emergency substitution: the coach picks who replaces his injured player, else the bench's best. */
    public function test_an_injured_player_waits_for_his_coachs_pick_then_the_benchs_best(): void
    {
        $match = $this->kickOff();
        $this->playTo($match, 3);
        $live = Cache::get("league-match:{$match->id}");
        $state = $live['state'];
        $team = &$state['teams'][$this->side];
        $hurt = collect($team['players'])->first(fn ($p) => $p['on'] && $p['slot_line'] !== 'gk');
        $bench = collect($team['players'])->filter(fn ($p) => ! $p['on'] && $p['out'] === '' && $p['slot'] === null)->values();
        foreach ($team['players'] as &$p) {
            if ($p['id'] === $hurt['id']) {
                [$p['on'], $p['out']] = [false, 'injury'];
            }
        }
        unset($p);
        $team['pending_injury'] = $hurt['id'];
        $team['missing']++;
        unset($team);
        $live['state'] = $state;
        Cache::forever("league-match:{$match->id}", $live);

        // Only a substitution of the injured player, and only by his coach.
        $this->assertSame($hurt['id'], CoachWindows::emergencyFor($state, $this->side));
        $this->order($match, ['type' => 'tactics', 'tactics' => ['style' => 70]], 409);
        $pick = $bench->last();
        $this->order($match, ['type' => 'sub', 'out' => $hurt['id'], 'in' => $pick['id']]);
        $next = Runner::tick($state, MatchOrders::forMinute($match->id, $state, ['home' => 'coach', 'away' => 'coach']));
        $mine = collect($next['teams'][$this->side]['players']);
        $this->assertTrue($mine->firstWhere('id', $pick['id'])['on']);
        $this->assertSame('injury', $mine->firstWhere('id', $hurt['id'])['out']);
        $this->assertArrayNotHasKey('pending_injury', $next['teams'][$this->side]);
        $this->assertSame(0, $next['teams'][$this->side]['missing']);

        // No pick: the engine brings on the bench's best at the next minute.
        $auto = Runner::tick($state, []);
        $this->assertArrayNotHasKey('pending_injury', $auto['teams'][$this->side]);
        $this->assertSame(0, $auto['teams'][$this->side]['missing']);
        $this->assertSame(1, collect($auto['out']['events'])->where('type', 'sub')->where('team', $this->side)->count());
    }

    /** [Sprint 43 C6] A replay lasts its round: once the next round starts, the result only, and the kept scene goes. */
    public function test_a_replay_lasts_until_the_next_round_starts(): void
    {
        $match = $this->kickOff();
        $this->playTo($match, 200);
        $this->actingAs($this->owner)->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->assertJsonPath('replayable', true)->assertJsonPath('expired', false);
        $this->artisan('matches:prune-replays')->expectsOutput('Deleted 0 replays.')->assertSuccessful();

        // A real league (not a development one, whose rounds come a minute apart), and a later match of its season starts.
        DB::table('leagues')->where('id', $this->league['id'])->update(['is_dev' => false]);
        $next = DB::table('fixtures')->where('season_id', $this->fixture->season_id)->where('scheduled_at', '>', $this->fixture->scheduled_at)
            ->where('is_bye', false)->orderBy('scheduled_at')->first();
        DB::table('fixtures')->where('id', $next->id)->update(['status' => 'live']);
        $old = $this->getJson("/api/v1/matches/{$match->id}/replay")->assertOk()->assertJsonPath('replayable', false)->assertJsonPath('expired', true)->json();
        $this->assertNull($old['ticks']);
        $this->assertNotEmpty($old['events']);
        $this->artisan('matches:prune-replays')->assertSuccessful();
        $this->assertFalse(DB::table('match_replays')->where('match_id', $match->id)->exists());
        // The result stays.
        $this->assertSame('finished', DB::table('fixtures')->where('id', $this->fixture->id)->value('status'));
        $this->assertNotNull(DB::table('match_reports')->where('match_id', $match->id)->first());
    }
}
