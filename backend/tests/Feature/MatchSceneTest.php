<?php

namespace Tests\Feature;

use App\Engine\MatchSetup;
use App\Http\Controllers\Api\MatchController;
use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** What the Unity scene draws, once per match [Sprint 02 B1, README 7.7]. */
class MatchSceneTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private object $match;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $mine = $league['my_club_id'];
        $fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        Carbon::setTestNow(Carbon::parse($fixture->scheduled_at, 'UTC'));
        MatchRunner::step();
        $this->match = DB::table('matches')->where('fixture_id', $fixture->id)->first();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_scene_gives_both_clubs_their_players_and_the_stadium(): void
    {
        $res = $this->actingAs($this->owner)->getJson("/api/v1/matches/{$this->match->id}/scene")->assertOk()
            ->assertJsonStructure([
                'id', 'stadium', 'light', 'kickoff_at', 'tick_ms', 'seed', 'captains' => ['home', 'away'], 'coach_looks' => ['home', 'away'],
                'clubs' => ['home' => ['id', 'name', 'code', 'primary', 'secondary', 'pattern', 'away_kit'], 'away' => ['id', 'name', 'code', 'primary', 'secondary']],
                'players' => ['home' => [['id', 'name', 'no', 'pos', 'line', 'starter']], 'away' => [['id', 'name', 'no', 'pos', 'line', 'starter']]],
            ]);

        $this->assertContains($res->json('stadium'), ['arena', 'classic']);
        $this->assertSame((int) $this->match->seed, $res->json('seed'), 'the seed, as the match view gives it');
        $this->assertContains($res->json('light'), ['night', 'dusk', 'day']);
        foreach (['home', 'away'] as $side) {
            $this->assertSame(11, collect($res->json("players.$side"))->where('starter', true)->count());
            $this->assertSame(1, collect($res->json("players.$side"))->where('starter', true)->where('pos', 'GK')->count());
        }
    }

    public function test_the_scene_carries_no_tactics_of_either_side(): void
    {
        $body = $this->actingAs($this->owner)->getJson("/api/v1/matches/{$this->match->id}/scene")->assertOk()->json();

        $keys = [];
        array_walk_recursive($body, function ($v, $k) use (&$keys) {
            $keys[] = $k;
        });
        $flat = json_encode($body);
        $this->assertStringNotContainsString('"tactics"', $flat);
        foreach (array_keys(MatchSetup::DEFAULT_TACTICS) as $hidden) {
            $this->assertNotContains($hidden, $keys, "The scene carries the tactic {$hidden}.");
        }
    }

    public function test_outsiders_do_not_see_the_scene(): void
    {
        $this->actingAs(User::factory()->create())->getJson("/api/v1/matches/{$this->match->id}/scene")->assertNotFound();
    }

    public function test_the_light_follows_the_hour_in_cairo(): void
    {
        $this->assertSame('day', MatchController::light(12));
        $this->assertSame('dusk', MatchController::light(16));
        $this->assertSame('night', MatchController::light(20));
        $this->assertSame('night', MatchController::light(3));
        $this->assertSame('day', MatchController::light(6));
    }
}
