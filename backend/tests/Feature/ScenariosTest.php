<?php

namespace Tests\Feature;

use App\League\MatchOrders;
use App\League\MatchRunner;
use App\League\Scenarios;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X23] The pre-match scenarios: set before, frozen at the lock, carried out once each at their moment. */
class ScenariosTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private object $fixture;

    private string $url;

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
        $this->url = "/api/v1/leagues/{$this->league['id']}/team/scenarios";
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function squad(): array
    {
        return DB::table('players')->where('club_id', $this->league['my_club_id'])->orderBy('id')->pluck('id')->all();
    }

    /** The match's own state, at a minute with a score. */
    private function state(object $match, int $minute, int $mine, int $theirs): array
    {
        $side = $this->fixture->home_id === $this->league['my_club_id'] ? 'home' : 'away';
        $other = $side === 'home' ? 'away' : 'home';

        return ['tick' => $minute, 'out' => ['minute' => [$minute, 0]], 'score' => [$side => $mine, $other => $theirs]] + json_decode($match->initial_state, true);
    }

    public function test_each_scenario_comes_at_its_moment_once(): void
    {
        $list = [
            ['kind' => 'trailing', 'minute' => 60, 'tactics' => ['pressing' => 80, 'tempo' => 75], 'sub' => ['out' => 1, 'in' => 2]],
            ['kind' => 'red_card', 'minute' => null, 'tactics' => ['style' => 30], 'sub' => null],
            ['kind' => 'leading', 'minute' => 75, 'tactics' => ['tempo' => 30], 'sub' => null],
        ];
        $kinds = fn (array $state, array $done = []) => array_column(Scenarios::due($state, 'home', $list, $done), 'kind');
        $at = fn (int $minute, int $diff, int $red = 0) => ['out' => ['minute' => [$minute, 0]], 'score' => ['home' => max(0, $diff), 'away' => max(0, -$diff)],
            'teams' => ['home' => ['stats' => ['red' => $red]]]];

        $this->assertSame([], $kinds($at(59, -1)));
        $this->assertSame(['trailing'], $kinds($at(60, -1)));
        $this->assertSame([], $kinds($at(80, -1), ['trailing']));
        $this->assertSame(['red_card'], $kinds($at(20, 0, 1)));
        $this->assertSame([], $kinds($at(74, 1)));
        $this->assertSame(['leading'], $kinds($at(75, 1)));
        $orders = Scenarios::due($at(60, -1), 'home', $list, [])[0]['orders'];
        $this->assertSame([['type' => 'tactics', 'team' => 'home', 'tactics' => ['pressing' => 80, 'tempo' => 75]],
            ['type' => 'sub', 'team' => 'home', 'out' => 1, 'in' => 2]], $orders);
    }

    public function test_the_coach_sets_them_within_the_rules(): void
    {
        $this->actingAs($this->owner);
        [$a, $b] = $this->squad();
        $this->putJson($this->url, ['scenarios' => [
            ['kind' => 'trailing', 'minute' => 65, 'tactics' => ['pressing' => 85, 'tempo' => 80], 'sub' => ['out' => $a, 'in' => $b]],
            ['kind' => 'leading', 'tactics' => ['style' => 25]],
        ]])->assertOk()->assertJsonPath('scenarios.0.minute', 65)->assertJsonPath('scenarios.1.minute', 75)
            ->assertJsonPath('scenarios.0.sub.in', $b)->assertJsonCount(3, 'scenario_kinds');
        $this->getJson("/api/v1/leagues/{$this->league['id']}/team/tactics")->assertJsonCount(2, 'scenarios');

        // One per kind, a minute in its range, my own players, and something to do.
        $this->putJson($this->url, ['scenarios' => [['kind' => 'leading', 'tactics' => ['tempo' => 1]], ['kind' => 'leading', 'tactics' => ['tempo' => 2]]]])
            ->assertStatus(422);
        $this->putJson($this->url, ['scenarios' => [['kind' => 'trailing', 'minute' => 30, 'tactics' => ['tempo' => 90]]]])->assertStatus(422);
        $theirs = DB::table('players')->where('club_id', '!=', $this->league['my_club_id'])->whereNotNull('club_id')->value('id');
        $this->putJson($this->url, ['scenarios' => [['kind' => 'red_card', 'sub' => ['out' => $a, 'in' => $theirs]]]])->assertStatus(422);
        $this->putJson($this->url, ['scenarios' => [['kind' => 'red_card']]])->assertStatus(422);
        $this->putJson($this->url, ['scenarios' => []])->assertOk()->assertJsonCount(0, 'scenarios');
    }

    public function test_frozen_at_the_lock_and_given_once_whether_the_coach_watches_or_not(): void
    {
        $this->actingAs($this->owner)->putJson($this->url, ['scenarios' => [['kind' => 'trailing', 'minute' => 60, 'tactics' => ['pressing' => 90]]]])->assertOk();
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC'));
        MatchRunner::step();
        $this->assertSame(409, $this->putJson($this->url, ['scenarios' => []])->status());
        $frozen = DB::table('fixture_sheets')->where('fixture_id', $this->fixture->id)->where('club_id', $this->league['my_club_id'])->value('scenarios');
        $this->assertSame('trailing', json_decode($frozen, true)[0]['kind']);

        $match = DB::table('matches')->where('fixture_id', $this->fixture->id)->first();
        $side = $this->fixture->home_id === $this->league['my_club_id'] ? 'home' : 'away';
        // Between the windows it waits [X42]: nothing at minute 59.
        $this->assertSame([[], []], MatchOrders::auto($match->id, $this->state($match, 59, 0, 1), [$side => 'coach', ($side === 'home' ? 'away' : 'home') => 'cpu']));
        // The coach is watching: in the window after minute 60 it still goes in.
        [$actions, $rows] = MatchOrders::auto($match->id, $this->state($match, 60, 0, 1), [$side => 'coach', ($side === 'home' ? 'away' : 'home') => 'cpu']);
        $mine = array_values(array_filter($actions, fn ($a) => $a['team'] === $side));
        $this->assertSame([['type' => 'tactics', 'team' => $side, 'tactics' => ['pressing' => 90]]], $mine);
        // Once only: what went in is kept (as the live runner does).
        DB::table('match_actions')->insert($rows);
        MatchOrders::forget($match->id);
        [$again] = MatchOrders::auto($match->id, $this->state($match, 75, 0, 1), [$side => 'coach', ($side === 'home' ? 'away' : 'home') => 'cpu']);
        $this->assertSame([], array_values(array_filter($again, fn ($a) => $a['team'] === $side)));
    }

    public function test_a_missed_match_plays_the_scenarios_with_the_assistant(): void
    {
        $this->actingAs($this->owner)->putJson($this->url, ['scenarios' => [
            ['kind' => 'trailing', 'minute' => 46, 'tactics' => ['pressing' => 95]],
            ['kind' => 'leading', 'minute' => 60, 'tactics' => ['tempo' => 5]],
        ]])->assertOk();
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC')->addMinutes(11));
        MatchRunner::step();
        $match = DB::table('matches')->where('fixture_id', $this->fixture->id)->first();
        $this->assertSame('instant', $match->mode);
        $rows = DB::table('match_actions')->where('match_id', $match->id)->where('source', 'scenario')->get();
        // At most one of each, and only for my side.
        $this->assertSame($rows->pluck('idempotency_key')->unique()->count(), $rows->count());
        $this->assertLessThanOrEqual(2, $rows->count());
        $side = $this->fixture->home_id === $this->league['my_club_id'] ? 'home' : 'away';
        $this->assertTrue($rows->every(fn ($r) => $r->side === $side));
        // My assistant leaves my tactics to my scenarios.
        $this->assertSame(0, DB::table('match_actions')->where('match_id', $match->id)->where('side', $side)->where('source', 'assistant')
            ->where('action', 'like', '%tactics%')->count());
    }
}
