<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Market\Pool;
use App\Market\Scout;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The scout, item by item of docs/features/scout.md [Sprint 26]. */
class ScoutTest extends TestCase
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
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(): string
    {
        return "/api/v1/leagues/{$this->league['id']}/scout";
    }

    private function ask(array $criteria = ['line' => 'att', 'min_overall' => 60], string $key = 'k1')
    {
        return $this->actingAs($this->owner)->postJson($this->url(), $criteria + ['idempotency_key' => $key]);
    }

    public function test_1_asking_pays_once_one_search_at_a_time_and_not_in_debt(): void
    {
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $cost = Scout::cost($this->league['id']);
        $this->assertGreaterThan(0, $cost);
        $this->ask()->assertOk()->assertJsonPath('requests.0.status', 'searching')
            ->assertJsonPath('finish_coins', (int) config('game.premium.price.finish_scout'));
        $this->ask()->assertOk();
        $this->assertSame($before - $cost, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame(1, DB::table('scout_requests')->count());
        $this->ask(key: 'k2')->assertConflict()->assertJsonPath('message', 'الكشاف يبحث لك الآن، انتظر تقريره.');

        DB::table('scout_requests')->update(['status' => 'done']);
        ClubLedger::post($this->mine, 'wages', -10_000_000, 'debt');
        $this->ask(key: 'k3')->assertConflict()->assertJsonPath('message', 'رصيد النادي لا يكفي.');
    }

    public function test_2_and_6_the_report_comes_on_time_with_the_coach_away_and_the_time_follows_the_season(): void
    {
        $this->ask()->assertOk();
        $r = DB::table('scout_requests')->first();
        // The season's length scales the day.
        $this->assertSame(intdiv((int) config('game.scout.hours') * 3600 * (int) DB::table('leagues')->where('id', $this->league['id'])->value('timer_scale'), 10000), (int) Carbon::parse($r->created_at, 'UTC')->diffInSeconds(Carbon::parse($r->finishes_at, 'UTC')));
        Carbon::setTestNow(Carbon::parse($r->finishes_at, 'UTC')->subMinute());
        $this->artisan('scout:due')->assertSuccessful();
        $this->assertSame('searching', DB::table('scout_requests')->value('status'));
        // The coach is away: the scheduler delivers it.
        Carbon::setTestNow(Carbon::parse($r->finishes_at, 'UTC'));
        $this->artisan('scout:due')->assertSuccessful();
        $this->assertSame('done', DB::table('scout_requests')->value('status'));
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'scout_report')->count());
    }

    public function test_3_the_five_players_match_every_criterion_and_come_from_outside_the_league(): void
    {
        $this->assertSame(15, config('game.scout.hours'));
        $this->ask(['line' => 'mid', 'min_overall' => 70, 'max_overall' => 80, 'max_age' => 30, 'max_value' => 20_000_000])->assertOk();
        Scout::report((int) DB::table('scout_requests')->value('id'));
        $ids = json_decode(DB::table('scout_requests')->value('result_player_ids'), true);
        $this->assertCount(5, $ids);
        $found = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', $ids)->get(['master_players.*']);
        $leagueClubs = DB::table('clubs')->where('league_id', $this->league['id'])->pluck('master_club_id')->all();
        foreach ($found as $p) {
            $this->assertSame('mid', $p->line);
            $this->assertTrue($p->overall >= 70 && $p->overall <= 80);
            $this->assertLessThanOrEqual(30, $p->age);
            $this->assertLessThanOrEqual(20_000_000, $p->value);
            $this->assertNotContains($p->master_club_id, $leagueClubs);
        }
    }

    public function test_4_only_this_club_buys_them_at_the_pool_price_until_the_pool_renews(): void
    {
        $this->ask()->assertOk();
        Scout::report((int) DB::table('scout_requests')->value('id'));
        $page = $this->getJson($this->url())->assertOk()->json('requests.0.players');
        $this->assertCount(5, $page);
        $this->assertSame('available', $page[0]['state']);
        $this->assertSame($page[0]['value'], $page[0]['price']);
        // Another coach cannot buy them.
        $coach = $this->approvedCoach($this->owner, $this->league);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->botClub($this->league['id'])}/claim")->assertCreated();
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$this->league['id']}/market/buy", ['player_id' => $page[0]['id'], 'idempotency_key' => 'x'])->assertConflict();
        // This club can.
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/market/buy", ['player_id' => $page[0]['id'], 'idempotency_key' => 'y'])->assertOk();
        $this->assertSame('mine', $this->getJson($this->url())->json('requests.0.players.0.state'));
        // The pool renews: the others go.
        $winter = DB::table('transfer_windows')->where('kind', 'winter')->first();
        Carbon::setTestNow(Carbon::parse($winter->opens_at, 'UTC')->addMinute());
        Pool::due();
        $states = collect($this->getJson($this->url())->json('requests.0.players'))->pluck('state')->sort()->values()->all();
        $this->assertSame(['gone', 'gone', 'gone', 'gone', 'mine'], $states);
    }

    public function test_5_nobody_found_pays_the_money_back(): void
    {
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->ask(['line' => 'gk', 'min_overall' => 99])->assertOk();
        Scout::report((int) DB::table('scout_requests')->value('id'));
        $this->assertSame('empty', DB::table('scout_requests')->value('status'));
        $this->assertSame($before, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame($before, ClubLedger::sum($this->mine));
        $this->assertStringContainsString('رُد لك المبلغ', $this->getJson('/api/v1/messages')->json('messages.0.body'));
    }
}
