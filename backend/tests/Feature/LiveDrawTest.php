<?php

namespace Tests\Feature;

use App\League\LeagueStarter;
use App\League\LiveDraw;
use App\League\RoundRobin;
use App\Models\League;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X26] The live draw: a hash before, the seed after, the slots and the cup from it, and the same for everyone. */
class LiveDrawTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private string $url;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create(['name' => 'المنظم']);
        $this->league = $this->makeLeague($this->owner, ['team_count' => 6, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->url = "/api/v1/leagues/{$this->league['id']}/draw";
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_order_is_fair_and_the_same_from_the_same_seed(): void
    {
        $ids = range(1, 16);
        $this->assertSame(LiveDraw::order($ids, 42), LiveDraw::order(array_reverse($ids), 42));
        $this->assertNotSame(LiveDraw::order($ids, 42), LiveDraw::order($ids, 43));
        $sorted = LiveDraw::order($ids, 42);
        sort($sorted);
        $this->assertSame($ids, $sorted);
        // Every club lands in the first slot about as often (no bias toward a slot).
        $first = array_fill_keys($ids, 0);
        for ($seed = 1; $seed <= 3200; $seed++) {
            $first[LiveDraw::order($ids, $seed)[0]]++;
        }
        $this->assertGreaterThan(130, min($first));
        $this->assertLessThan(270, max($first));
    }

    public function test_the_owner_sets_it_the_hash_is_shown_and_the_seed_stays_hidden(): void
    {
        $this->actingAs($this->owner);
        $this->putJson($this->url, ['draw_at' => GameClock::now()->subMinute()->toIso8601ZuluString()])->assertStatus(422);
        $this->putJson($this->url, ['draw_at' => GameClock::now()->addDays(3)->toIso8601ZuluString()])->assertStatus(422);
        $at = GameClock::now()->addHour();
        $res = $this->putJson($this->url, ['draw_at' => $at->toIso8601ZuluString()])->assertOk()->json();
        $this->assertSame(64, strlen($res['commit']));
        $this->assertNull($res['seed']);
        $this->assertSame([], $res['slots']);
        $this->assertStringNotContainsString('draw_seed', json_encode($this->getJson("/api/v1/leagues/{$this->league['id']}")->json()));
        // Moving it keeps the same seed, so the hash never changes.
        $again = $this->putJson($this->url, ['draw_at' => $at->copy()->addMinutes(30)->toIso8601ZuluString()])->json();
        $this->assertSame($res['commit'], $again['commit']);
        // Only the owner.
        $this->actingAs(User::factory()->create())->putJson($this->url, ['draw_at' => $at->toIso8601ZuluString()])->assertStatus(403);
    }

    public function test_at_its_time_the_seed_orders_the_calendar_and_the_cup_and_can_be_checked(): void
    {
        $this->actingAs($this->owner)->putJson($this->url, ['draw_at' => GameClock::now()->addHour()->toIso8601ZuluString()])->assertOk();
        $commit = $this->getJson($this->url)->json('commit');
        Carbon::setTestNow(GameClock::now()->addMinutes(61));
        Artisan::call('leagues:start');
        $draw = $this->getJson($this->url)->assertOk()->json();
        $this->assertNotNull($draw['drawn_at']);
        $this->assertSame($commit, hash('sha256', "legends-draw:{$this->league['id']}:{$draw['seed']}"));
        $clubs = DB::table('clubs')->where('league_id', $this->league['id'])->pluck('id')->map(fn ($i) => (int) $i)->all();
        $this->assertSame(LiveDraw::order($clubs, $draw['seed']), array_column(array_column($draw['slots'], 'club'), 'id'));
        $this->assertSame([1, 2, 3, 4, 5, 6], array_column($draw['slots'], 'slot'));
        $this->assertCount(3, $draw['league_round']);
        $this->assertNotEmpty($draw['cup_round']);
        $this->assertSame('المنظم', $draw['committee']['owner']);
        // The calendar was made from the drawn slots: the first round pairs them as the round robin does.
        $pairs = array_map(fn ($m) => [$m['home']['id'], $m['away']['id']], $draw['league_round']);
        $this->assertSame(RoundRobin::rounds(array_column(array_column($draw['slots'], 'club'), 'id'))[0]['matches'], $pairs);
        $this->putJson($this->url, ['draw_at' => GameClock::now()->addHour()->toIso8601ZuluString()])->assertStatus(409);
        // A second run draws nothing more.
        $this->assertSame(0, LiveDraw::due());
    }

    public function test_a_league_that_starts_before_its_draw_is_drawn_first(): void
    {
        $this->actingAs($this->owner)->putJson($this->url, ['draw_at' => GameClock::now()->addDay()->toIso8601ZuluString()])->assertOk();
        LeagueStarter::start(League::find($this->league['id']));
        $this->assertNotNull(League::find($this->league['id'])->drawn_at);
        $this->assertNotEmpty($this->getJson($this->url)->json('slots'));
    }
}
