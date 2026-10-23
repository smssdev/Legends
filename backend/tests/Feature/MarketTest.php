<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Market\Market;
use App\Market\Pool;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The market with the pool and the bot clubs [PLAN 2.7, Sprint 24]. */
class MarketTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(clubs: 20, full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path = ''): string
    {
        return "/api/v1/leagues/{$this->league['id']}/market{$path}";
    }

    private function poolPlayer(): object
    {
        return DB::table('players')->where('league_id', $this->league['id'])->whereNull('club_id')->where('in_pool', true)->orderBy('value')->first();
    }

    private function bot(): int
    {
        return (int) DB::table('clubs')->where('league_id', $this->league['id'])->whereNull('user_id')->orderBy('id')->value('id');
    }

    private function assertBooks(): void
    {
        foreach (DB::table('clubs')->where('league_id', $this->league['id'])->get() as $c) {
            $this->assertSame((int) $c->balance, ClubLedger::sum($c->id));
        }
    }

    public function test_the_pool_comes_with_the_league_from_outside_its_clubs(): void
    {
        $pool = DB::table('players')->where('league_id', $this->league['id'])->where('in_pool', true)->get();
        $this->assertGreaterThan(20, $pool->count());
        $this->assertLessThanOrEqual(300, $pool->count());
        $leagueMasters = DB::table('clubs')->where('league_id', $this->league['id'])->pluck('master_club_id');
        $this->assertSame(0, DB::table('master_players')->whereIn('id', $pool->pluck('master_player_id'))->whereIn('master_club_id', $leagueMasters)->count());

        // The winter window renews it once: the old ones leave, new ones come.
        $winter = DB::table('transfer_windows')->where('kind', 'winter')->first();
        Carbon::setTestNow(Carbon::parse($winter->opens_at, 'UTC')->addMinute());
        $this->assertSame(1, Pool::due());
        $this->assertSame(0, Pool::due());
        $this->assertSame(0, DB::table('players')->whereIn('id', $pool->pluck('id'))->where('in_pool', true)->count());
    }

    public function test_buying_from_the_pool_at_its_value_once(): void
    {
        $p = $this->poolPlayer();
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->actingAs($this->owner)->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'k1'])->assertOk()
            ->assertJsonPath('balance', $before - (int) $p->value);
        // The same tap again: nothing more.
        $this->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'k1'])->assertOk()->assertJsonPath('balance', $before - (int) $p->value);
        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertFalse((bool) DB::table('players')->where('id', $p->id)->value('in_pool'));
        // Someone else's now.
        $this->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'k2'])->assertConflict();
        $this->assertBooks();
    }

    public function test_no_money_no_player(): void
    {
        $p = DB::table('players')->where('league_id', $this->league['id'])->where('in_pool', true)->orderByDesc('value')->first();
        ClubLedger::post($this->mine, 'wages', -((int) DB::table('clubs')->where('id', $this->mine)->value('balance')) + 10, 'drain');
        $this->actingAs($this->owner)->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'k'])->assertConflict()
            ->assertJsonPath('message', 'رصيد النادي لا يكفي.');
        $this->assertNull(DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertTrue((bool) DB::table('players')->where('id', $p->id)->value('in_pool'));
    }

    public function test_selling_to_the_pool_pays_70_percent_without_the_training(): void
    {
        $p = DB::table('players')->where('club_id', $this->mine)->orderByDesc('value')->first();
        // Trained since: his value went up, his base did not.
        DB::table('players')->where('id', $p->id)->update(['value' => (int) $p->value * 2, 'training_bonus' => 3]);
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->actingAs($this->owner)->postJson($this->url('/sell'), ['player_id' => $p->id, 'idempotency_key' => 's1'])->assertOk()
            ->assertJsonPath('balance', $before + intdiv((int) $p->base_value * 7000, 10000));
        $this->assertTrue((bool) DB::table('players')->where('id', $p->id)->value('in_pool'));
        // A buy-train-sell round trip loses money: the pool sells at his value, buys back at 70% of the base.
        $this->assertBooks();
        // Never below 16 players.
        $left = DB::table('players')->where('club_id', $this->mine)->pluck('id');
        foreach ($left->slice(0, $left->count() - 16) as $i => $id) {
            $this->postJson($this->url('/sell'), ['player_id' => $id, 'idempotency_key' => "s{$i}x"])->assertOk();
        }
        $this->postJson($this->url('/sell'), ['player_id' => DB::table('players')->where('club_id', $this->mine)->value('id'), 'idempotency_key' => 'last'])
            ->assertConflict()->assertJsonPath('message', 'لا يمكن أن ينزل فريقك عن 16 لاعباً.');
    }

    public function test_a_bot_sells_at_125_percent_and_keeps_18_players_and_2_keepers(): void
    {
        $bot = $this->bot();
        // It has 19 (one bought from the pool), so it can sell one.
        DB::table('players')->where('id', $this->poolPlayer()->id)->update(['club_id' => $bot, 'in_pool' => false]);
        $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $bot)
            ->where('master_players.line', '!=', 'gk')->orderBy('players.value')->select('players.*')->first();
        $botBefore = (int) DB::table('clubs')->where('id', $bot)->value('balance');
        $price = intdiv((int) $p->value * 12500, 10000);
        $this->actingAs($this->owner)->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'b1'])->assertOk();
        $this->assertSame($botBefore + $price, (int) DB::table('clubs')->where('id', $bot)->value('balance'));
        // At 18 now: the next sale is refused.
        $next = DB::table('players')->where('club_id', $bot)->orderBy('value')->first();
        $this->postJson($this->url('/buy'), ['player_id' => $next->id, 'idempotency_key' => 'b2'])->assertConflict()
            ->assertJsonPath('message', 'نادي الحاسوب لا يبيع إن نزل عن 18 لاعباً.');
        // A human's player is not for sale here.
        $coach = $this->approvedCoach($this->owner, $this->league);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->bot()}/claim")->assertCreated();
        $theirs = DB::table('players')->where('club_id', DB::table('clubs')->where('user_id', $coach->id)->value('id'))->value('id');
        $this->actingAs($this->owner)->postJson($this->url('/buy'), ['player_id' => $theirs, 'idempotency_key' => 'b3'])->assertConflict();
        $this->assertBooks();
    }

    public function test_the_market_closes_in_the_last_quarter(): void
    {
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->first();
        DB::table('seasons')->where('id', $season->id)->update(['rounds_played' => $season->lock_from_round - 1]);
        $this->actingAs($this->owner)->getJson($this->url())->assertOk()->assertJsonPath('closed', 'السوق مغلق في آخر ربع من الموسم.');
        $this->postJson($this->url('/buy'), ['player_id' => $this->poolPlayer()->id, 'idempotency_key' => 'late'])->assertConflict();
    }

    public function test_a_bot_left_short_buys_from_the_pool(): void
    {
        $bot = $this->bot();
        // A forced sale took three of its players.
        DB::table('players')->where('club_id', $bot)->orderByDesc('value')->limit(3)->update(['club_id' => null, 'in_pool' => true]);
        $this->assertSame(15, DB::table('players')->where('club_id', $bot)->count());
        ClubLedger::post($bot, 'opening', 10_000_000, 'test:bot-money');
        $this->assertSame(3, Market::refill($bot));
        $this->assertSame(18, DB::table('players')->where('club_id', $bot)->count());
        $this->assertSame(3, DB::table('club_transactions')->where('club_id', $bot)->where('type', 'pool_buy')->count());
        $this->assertBooks();
    }

    public function test_the_market_page_lists_the_pool_the_bots_and_my_players(): void
    {
        $line = DB::table('master_players')->where('id', $this->poolPlayer()->master_player_id)->value('line');
        $page = $this->actingAs($this->owner)->getJson($this->url()."?line={$line}")->assertOk()->json();
        $this->assertNull($page['closed']);
        $this->assertNotEmpty($page['players']);
        $this->assertTrue(collect($page['players'])->every(fn ($p) => $p['line'] === $line && $p['price'] === $p['value'] && $p['club'] === null));
        $bots = $this->getJson($this->url().'?source=bots')->json();
        $this->assertTrue(collect($bots['players'])->every(fn ($p) => $p['price'] === intdiv($p['value'] * 12500, 10000)));
        $this->assertCount(18, $bots['mine']);
        $this->actingAs(User::factory()->create())->getJson($this->url())->assertForbidden();
    }
}
