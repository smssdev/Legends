<?php

namespace Tests\Feature;

use App\Experience\PlayerMilestones;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 64] The intro match (B1), the funnel (B2), "since your last visit" (W3), the breakdowns (W5) and the milestones (B8). */
class GameExperienceTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => '2026-10-22T10:00:00Z']);
        $this->mine = $this->league['my_club_id'];
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}/team/{$path}";
    }

    /** A finished match of my club: won 2-0, its sheets with these players' goals. */
    private function finished(array $goals = [], int $minutesAgo = 60): int
    {
        $f = DB::table('fixtures')->where('season_id', DB::table('seasons')->where('league_id', $this->league['id'])->value('id'))->where('status', 'scheduled')
            ->where(fn ($q) => $q->where('home_id', $this->mine)->orWhere('away_id', $this->mine))->whereNotNull('home_id')->whereNotNull('away_id')->orderBy('scheduled_at')->first();
        $home = $f->home_id === $this->mine;
        DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $home ? 2 : 0, 'away_goals' => $home ? 0 : 2, 'scheduled_at' => GameClock::now()->subMinutes($minutesAgo)]);
        $now = GameClock::now();
        $match = DB::table('matches')->insertGetId(['fixture_id' => $f->id, 'seed' => 1, 'engine_version' => 1, 'config_snapshot' => '{}', 'initial_state' => '{}', 'state' => '{}',
            'home_goals' => $home ? 2 : 0, 'away_goals' => $home ? 0 : 2, 'mode' => 'league', 'status' => 'finished', 'started_at' => $now, 'finished_at' => $now, 'created_at' => $now, 'updated_at' => $now]);
        $players = DB::table('players')->where('club_id', $this->mine)->orderBy('id')->limit(11)->pluck('id');
        DB::table('match_stats')->insert(['match_id' => $match, 'club_id' => $this->mine, 'counters' => '{}',
            'players' => json_encode($players->map(fn ($id) => ['id' => $id, 'played' => true, 'rating' => 650, 'goals' => $goals[$id] ?? 0, 'assists' => 0])->all())]);

        return $match;
    }

    public function test_since_your_last_visit_once_per_absence(): void
    {
        $this->assertNull($this->getJson($this->url('summary'))->assertOk()->json('since'));
        $match = $this->finished();
        $since = $this->getJson($this->url('summary'))->json('since');
        $this->assertSame(1, $since['matches']);
        $this->assertSame($match, $since['last']['match_id']);
        $this->assertSame(1, $since['last']['result']);
        $this->assertSame(1, $since['position']['now'], 'the only win so far');
        $this->assertIsInt($since['position']['before'], 'the table as it was before the unseen matches');
        $this->assertSame(0, $since['offers']);
        // Seen (opened or skipped): gone until the next absence.
        $this->postJson($this->url('missed/seen'))->assertOk();
        $this->assertNull($this->getJson($this->url('summary'))->json('since'));
    }

    public function test_every_number_says_where_it_comes_from_and_only_of_my_club(): void
    {
        foreach (['chemistry', 'strength', 'morale', 'rating'] as $what) {
            $e = $this->getJson($this->url("explain/{$what}"))->assertOk()->assertJsonStructure(['what', 'value', 'parts' => ['*' => ['label', 'value']], 'topic'])->json();
            $this->assertNotEmpty($e['parts'], $what);
        }
        $this->assertSame((int) DB::table('clubs')->where('id', $this->mine)->value('morale'), $this->getJson($this->url('explain/morale'))->json('value'));
        $this->getJson($this->url('explain/tactics'))->assertNotFound();
        $this->actingAs(User::factory()->create())->getJson($this->url('explain/morale'))->assertForbidden();
    }

    public function test_a_tenth_goal_and_a_first_man_of_the_match_once_each_with_a_message(): void
    {
        $scorer = (int) DB::table('players')->where('club_id', $this->mine)->orderBy('id')->value('id');
        for ($i = 0; $i < 4; $i++) {
            $this->finished([$scorer => 2], 600 - $i);
        }
        $state = ['teams' => ['home' => ['players' => [['id' => $scorer, 'on' => true, 'out' => '', 'st' => ['r' => 900]]]], 'away' => ['players' => []]]];
        PlayerMilestones::after($this->finished([$scorer => 2]), $this->mine, $state);
        $kinds = DB::table('player_milestones')->where('player_id', $scorer)->orderBy('kind')->get(['kind', 'value'])->map(fn ($m) => "{$m->kind}:{$m->value}")->all();
        $this->assertSame(['goals:10', 'motm:1'], $kinds);
        $this->assertSame(2, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'player_milestone')->count());
        // A match after: nothing new crossed, nothing again.
        PlayerMilestones::after($this->finished([$scorer => 0]), $this->mine, ['teams' => ['home' => ['players' => []], 'away' => ['players' => []]]]);
        $this->assertSame(2, DB::table('player_milestones')->count());

        $card = $this->getJson($this->url('summary'))->json('milestones');
        $this->assertCount(2, $card);
        $this->postJson($this->url('milestones/seen'))->assertOk()->assertJsonPath('seen', 2);
        $this->assertSame([], $this->getJson($this->url('summary'))->json('milestones'));
    }

    public function test_the_intro_match_with_its_three_moments_and_the_funnel(): void
    {
        // Off, as in production: the intro still plays, and only it.
        config(['game.simulator.enabled' => false]);
        $new = User::factory()->create();
        $intro = $this->actingAs($new)->postJson('/api/v1/sim/intro')->assertCreated()->json();
        $this->postJson("/api/v1/sim/matches/{$intro['id']}/ticks")->assertOk();
        $this->getJson("/api/v1/sim/matches/{$intro['id']}")->assertOk();
        $this->postJson('/api/v1/sim/matches', ['home_id' => 1, 'away_id' => 2])->assertNotFound();
        $moments = $intro['intro']['moments'];
        $this->assertSame(['style', 'effect', 'sub'], array_column($moments, 'kind'));
        $this->assertSame($moments[0]['minute'] + (int) config('game.experience.intro.effect_after'), $moments[1]['minute']);
        $this->assertNotSame('', $moments[0]['text']);
        $this->assertNotNull($new->fresh()->intro_started_at);
        $this->postJson('/api/v1/sim/intro/finished')->assertOk();
        $this->assertNotNull($new->fresh()->intro_finished_at);
    }

    public function test_the_admin_sees_the_funnel_as_counts_only(): void
    {
        DB::table('users')->where('id', $this->owner->id)->update(['intro_started_at' => GameClock::now()]);
        $this->finished();
        // From the site: Sanctum's session.
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($this->owner)->getJson('/api/v1/admin/funnel')->assertForbidden();
        $admin = User::factory()->create(['role' => 'admin']);
        $steps = collect($this->actingAs($admin)->getJson('/api/v1/admin/funnel?days=30')->assertOk()->json('steps'))->keyBy('step');
        $this->assertSame(['signed_up', 'intro_started', 'intro_finished', 'club_taken', 'first_lineup', 'first_match'], $steps->keys()->all());
        $this->assertSame(2, $steps['signed_up']['count']);
        $this->assertSame(1, $steps['intro_started']['count']);
        $this->assertSame(50, $steps['intro_started']['pct']);
        $this->assertSame(1, $steps['club_taken']['count']);
        $this->assertSame(1, $steps['first_match']['count']);
    }
}
