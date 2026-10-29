<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Market\Buyer;
use App\Market\Market;
use App\Market\Pool;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
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
        $this->template(full: true);
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
        $this->assertGreaterThan(5, $pool->count());
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
            ->assertJsonPath('message', 'أموال ناديك غير كافية، يلزم توفر 50% على الأقل من قيمة اللاعب نقداً.');
        $this->assertNull(DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertTrue((bool) DB::table('players')->where('id', $p->id)->value('in_pool'));
    }

    /** My dearest outfield players (a keeper may not be sold below two; which ties come first differs by database). */
    private function dearest(): array
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->where('master_players.line', '!=', 'gk')->orderByDesc('players.value')->orderBy('players.id')->select('players.*')->limit(2)->get()->all();
    }

    public function test_the_instant_sale_pays_the_full_value_with_the_training_for_a_fee(): void
    {
        $p = $this->dearest()[0];
        // Trained since: his value went up, and the sale pays it [X6].
        $value = (int) $p->value * 2;
        DB::table('players')->where('id', $p->id)->update(['value' => $value, 'training_bonus' => 3]);
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        // A fair league: no coins, so the fee is 10% of his value from the club.
        $this->actingAs($this->owner)->postJson($this->url('/sell'), ['player_id' => $p->id, 'idempotency_key' => 's1'])->assertOk()
            ->assertJsonPath('balance', $before - intdiv($value, 10) + $value);
        $this->postJson($this->url('/sell'), ['player_id' => $p->id, 'idempotency_key' => 's1'])->assertOk()->assertJsonPath('balance', $before - intdiv($value, 10) + $value);
        $this->assertTrue((bool) DB::table('players')->where('id', $p->id)->value('in_pool'));
        $this->assertBooks();
        // Never below 16 players.
        $left = DB::table('players')->where('club_id', $this->mine)->count();
        $outfield = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->where('master_players.line', '!=', 'gk')->orderBy('players.id')->pluck('players.id');
        foreach ($outfield->slice(0, $left - 16) as $i => $id) {
            $this->postJson($this->url('/sell'), ['player_id' => $id, 'idempotency_key' => "s{$i}x"])->assertOk();
        }
        $this->postJson($this->url('/sell'), ['player_id' => DB::table('players')->where('club_id', $this->mine)->value('id'), 'idempotency_key' => 'last'])
            ->assertConflict()->assertJsonPath('message', 'لا يمكن أن ينزل فريقك عن 16 لاعباً.');
    }

    public function test_the_instant_sale_costs_5_coins_outside_a_fair_league(): void
    {
        DB::table('leagues')->where('id', $this->league['id'])->update(['fair_league' => false]);
        $p = $this->dearest()[0];
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->actingAs($this->owner)->postJson($this->url('/sell'), ['player_id' => $p->id, 'idempotency_key' => 'c1'])->assertConflict();
        Wallet::post($this->owner->id, 'daily', 7, 'gift');
        $this->postJson($this->url('/sell'), ['player_id' => $p->id, 'idempotency_key' => 'c2'])->assertOk()->assertJsonPath('balance', $before + (int) $p->value);
        $this->assertSame(2, Wallet::balance($this->owner->id));
        $this->assertBooks();
    }

    public function test_a_listed_player_is_sold_to_an_outside_buyer_later_the_dearer_he_is(): void
    {
        $tr = "/api/v1/leagues/{$this->league['id']}/transfers/listings";
        [$a, $b] = $this->dearest();
        // Room enough for the whole 250% [Sprint 23].
        DB::table('leagues')->where('id', $this->league['id'])->update(['money_scale' => (int) $a->value * 100]);
        $this->actingAs($this->owner);
        // The cap: 250% of his value for his own player.
        $this->postJson($tr, ['player_id' => $a->id, 'price' => intdiv((int) $a->value * 25000, 10000) + 1])->assertUnprocessable();
        $this->postJson($tr, ['player_id' => $a->id, 'price' => intdiv((int) $a->value * 25000, 10000)])->assertOk();
        $this->postJson($tr, ['player_id' => $b->id, 'price' => (int) $b->value])->assertOk();
        $at = fn ($p) => Carbon::parse(DB::table('transfer_listings')->where('player_id', $p->id)->value('sells_at'), 'UTC');
        $scale = (int) DB::table('leagues')->where('id', $this->league['id'])->value('timer_scale');
        $this->assertGreaterThan($at($b), $at($a));
        // At his value: six hours on the season's scale, moved by the buyer's demand for his age and rating, give or take a fifth.
        $age = (int) DB::table('master_players')->where('id', $b->master_player_id)->value('age');
        $demand = intdiv(Buyer::demand('demand_age', $age) * Buyer::demand('demand_overall', (int) $b->overall), 10000);
        $six = intdiv(intdiv(6 * 3600 * $scale, 10000) * $demand, 10000);
        $this->assertEqualsWithDelta($six, GameClock::now()->diffInSeconds($at($b)), intdiv($six, 5) + 1);

        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        Carbon::setTestNow($at($b)->copy()->addSecond());
        $this->assertSame(1, Buyer::due());
        $this->assertNull(DB::table('players')->where('id', $b->id)->value('club_id'));
        $this->assertFalse((bool) DB::table('players')->where('id', $b->id)->value('in_pool'));
        $this->assertSame($before + (int) $b->value, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'listing_sold')->count());
        Carbon::setTestNow($at($a)->copy()->addSecond());
        $this->assertSame(1, Buyer::due());
        $this->assertSame(0, DB::table('transfer_listings')->count());
        // What he brought above his value is its own line, counted against the season's room.
        $this->assertSame(intdiv((int) $a->value * 25000, 10000) - (int) $a->value, (int) DB::table('club_transactions')->where('club_id', $this->mine)->where('type', 'listing_premium')->sum('amount'));
        $this->assertBooks();
    }

    public function test_the_young_and_good_sell_sooner_than_the_old_and_weak(): void
    {
        $id = $this->league['id'];
        // The same price and value: 20 and 80 against 33 and 60.
        $young = Buyer::wait(1_000_000, 1_000_000, $id, 10000, 20, 80);
        $old = Buyer::wait(1_000_000, 1_000_000, $id, 10000, 33, 60);
        $this->assertSame(6 * 3600, Buyer::wait(1_000_000, 1_000_000, $id, 10000));
        $this->assertLessThan(6 * 3600, $young);
        $this->assertGreaterThan(2 * $young, $old);
        // At the cap, about eight days.
        $this->assertSame(192 * 3600, Buyer::wait(2_500_000, 1_000_000, $id, 10000));
    }

    public function test_four_listings_at_a_time_and_the_seasons_room_above_the_value(): void
    {
        $tr = "/api/v1/leagues/{$this->league['id']}/transfers/listings";
        $mine = DB::table('players')->where('club_id', $this->mine)->orderByDesc('value')->orderBy('id')->limit(5)->get();
        $this->actingAs($this->owner);
        foreach ($mine->take(4) as $p) {
            $this->postJson($tr, ['player_id' => $p->id, 'price' => (int) $p->value])->assertOk();
        }
        $this->postJson($tr, ['player_id' => $mine[4]->id, 'price' => (int) $mine[4]->value])->assertUnprocessable()
            ->assertJsonPath('message', 'تعرض 4 لاعبين الآن، وهذا أقصى ما يُعرض في نفس الوقت: اسحب أحدهم أو انتظر بيعه.');
        // A new price for one listed already is fine.
        $this->postJson($tr, ['player_id' => $mine[0]->id, 'price' => (int) $mine[0]->value + 1])->assertOk();
        $this->deleteJson("{$tr}/{$mine[3]->id}")->assertOk();
        $this->postJson($tr, ['player_id' => $mine[4]->id, 'price' => (int) $mine[4]->value])->assertOk();

        // The room: 4% of the money scale; what one listing asks above the value is kept from the others' caps.
        DB::table('transfer_listings')->delete();
        [$a, $b] = [$mine[0], $mine[1]];
        DB::table('leagues')->where('id', $this->league['id'])->update(['money_scale' => 50_000_000]);
        $room = Buyer::room($this->mine);
        $this->assertSame(2_000_000, $room['allowance']);
        $capA = Buyer::cap($a, $this->mine);
        $this->assertSame(min(intdiv((int) $a->value * 25000, 10000), (int) $a->value + 2_000_000), $capA);
        $this->postJson($tr, ['player_id' => $a->id, 'price' => (int) $a->value + 1_500_000])->assertOk();
        $this->assertSame(min(intdiv((int) $b->value * 25000, 10000), (int) $b->value + 500_000), Buyer::cap($b, $this->mine));
        // His own ask does not count against him.
        $this->assertSame($capA, Buyer::cap($a, $this->mine));
        $this->getJson($this->url().'?source=pool')->assertOk()->assertJsonPath('selling.max_listings', 4)->assertJsonPath('selling.room', 500_000);
    }

    public function test_a_bought_player_is_capped_at_his_value(): void
    {
        $p = $this->poolPlayer();
        $this->actingAs($this->owner)->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'k1'])->assertOk();
        $tr = "/api/v1/leagues/{$this->league['id']}/transfers/listings";
        $this->postJson($tr, ['player_id' => $p->id, 'price' => (int) $p->value + 1])->assertUnprocessable();
        $this->postJson($tr, ['player_id' => $p->id, 'price' => (int) $p->value])->assertOk();
    }

    public function test_the_pool_renews_every_4_hours_from_every_league_at_this_leagues_level(): void
    {
        $first = DB::table('players')->where('league_id', $this->league['id'])->where('in_pool', true)->pluck('id');
        // Players of another league in the data, as strong as this one, one per line.
        $abroad = DB::table('master_clubs')->insertGetId(['data_version' => '2026', 'name' => 'Abroad FC', 'code' => 'ABR', 'league_name' => 'Abroad League',
            'strength_cp' => 8400, 'color_primary' => '#000000', 'color_secondary' => '#FFFFFF']);
        foreach (['GK' => 'gk', 'CB' => 'def', 'CM' => 'mid', 'ST' => 'att'] as $pos => $line) {
            DB::table('master_players')->insert(['data_version' => '2026', 'external_id' => 990000 + crc32($pos) % 1000, 'master_club_id' => $abroad, 'name' => "Abroad {$pos}",
                'position' => $pos, 'line' => $line, 'age' => 25, 'overall' => 84, 'potential' => 86, 'value' => 2_000_000,
                'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70]);
        }
        $this->assertSame(0, Pool::due());
        Carbon::setTestNow(GameClock::now()->addHours(4));
        $this->assertSame(1, Pool::due());
        $this->assertSame(0, DB::table('players')->whereIn('id', $first)->where('in_pool', true)->count());
        $pool = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.league_id', $this->league['id'])->where('players.in_pool', true)->get(['master_players.line', 'players.overall']);
        $this->assertEqualsCanonicalizing(['gk', 'def', 'mid', 'att'], $pool->pluck('line')->unique()->values()->all());
        $levels = DB::table('players')->where('league_id', $this->league['id'])->whereNotNull('club_id')->orderBy('overall')->pluck('overall');
        $this->assertGreaterThanOrEqual($levels[intdiv($levels->count() * 40, 100)], $pool->min('overall'));
    }

    public function test_from_mid_season_the_pool_brings_stars_from_the_parallel_leagues(): void
    {
        $best = (int) DB::table('players')->where('league_id', $this->league['id'])->whereNotNull('club_id')->max('overall');
        $abroad = DB::table('master_clubs')->insertGetId(['data_version' => '2026', 'name' => 'Star FC', 'code' => 'STR', 'league_name' => 'Star League',
            'strength_cp' => 9000, 'color_primary' => '#000000', 'color_secondary' => '#FFFFFF']);
        foreach ([1, 2, 3] as $i) {
            DB::table('master_players')->insert(['data_version' => '2026', 'external_id' => 995000 + $i, 'master_club_id' => $abroad, 'name' => "Star {$i}",
                'position' => 'ST', 'line' => 'att', 'age' => 27, 'overall' => $best + 1, 'potential' => $best + 2, 'value' => 90_000_000,
                'pac' => 90, 'sho' => 90, 'pas' => 85, 'dri' => 90, 'def' => 40, 'phy' => 80]);
        }
        $stars = fn () => DB::table('players')->where('league_id', $this->league['id'])->where('in_pool', true)->where('pool_star', true)->count();
        Pool::renew($this->league['id']);
        $this->assertSame(0, $stars(), 'no stars before mid-season');

        $season = DB::table('seasons')->where('league_id', $this->league['id'])->first();
        DB::table('seasons')->where('id', $season->id)->update(['rounds_played' => intdiv($season->rounds + 1, 2)]);
        Pool::renew($this->league['id']);
        $this->assertSame(3, $stars());
        $this->assertGreaterThanOrEqual($best, (int) DB::table('players')->where('league_id', $this->league['id'])->where('pool_star', true)->min('overall'));
        // The transfer list shows them first, marked.
        $list = $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/market?line=att")->assertOk()->json('players');
        $this->assertTrue($list[0]['star']);
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
        $page = $this->actingAs($this->owner)->getJson($this->url()."?source=pool&line={$line}")->assertOk()->json();
        $this->assertNull($page['closed']);
        $this->assertNotEmpty($page['players']);
        $this->assertTrue(collect($page['players'])->every(fn ($p) => $p['line'] === $line && $p['price'] === $p['value'] && $p['club'] === null));
        $bots = $this->getJson($this->url().'?source=bots')->json();
        $this->assertTrue(collect($bots['players'])->every(fn ($p) => $p['price'] === intdiv($p['value'] * 12500, 10000)));
        $this->assertCount(18, $bots['mine']);
        $this->actingAs(User::factory()->create())->getJson($this->url())->assertForbidden();
    }

    /** [UP11] The owner's spec (5): one list per line with each seller, and buying with the deal's coins or cash + coins. */
    public function test_the_transfer_list_and_buying_with_the_registration_coins_or_cash_and_coins(): void
    {
        DB::table('leagues')->where('id', $this->league['id'])->update(['fair_league' => false]);
        $p = $this->poolPlayer();
        $line = DB::table('master_players')->where('id', $p->master_player_id)->value('line');
        $list = $this->actingAs($this->owner)->getJson($this->url()."?line={$line}")->assertOk()->json();
        $this->assertNotNull($list['renews_at']);
        $this->assertTrue(collect($list['players'])->every(fn ($x) => $x['line'] === $line));
        $this->assertContains('world', collect($list['players'])->pluck('seller.kind')->all());
        $this->assertContains('bot', collect($list['players'])->pluck('seller.kind')->all());

        // Enough cash: the price and one or two coins to register it.
        Wallet::post($this->owner->id, 'daily', 300, 'seed');
        $q = $this->getJson($this->url('/buy-quote')."?player_id={$p->id}")->assertOk()->json();
        $this->assertSame(0, $q['short']);
        $this->assertContains($q['doc_coins'], [1, 2]);
        $this->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'a'])->assertOk();
        $this->assertSame(300 - $q['doc_coins'], Wallet::balance($this->owner->id));

        // Short of cash with more than half: all the cash, and coins for the rest (one per 200,000).
        $next = DB::table('players')->where('league_id', $this->league['id'])->where('in_pool', true)->orderByDesc('value')->first();
        $price = (int) $next->value;
        $cash = intdiv($price * 3, 4);
        ClubLedger::post($this->mine, 'wages', $cash - (int) DB::table('clubs')->where('id', $this->mine)->value('balance'), 'set-cash');
        $q = $this->getJson($this->url('/buy-quote')."?player_id={$next->id}")->assertOk()->json();
        $this->assertSame(['cash' => $cash, 'coins' => intdiv($price - $cash + 199_999, 200_000)], $q['compensate']);
        $this->postJson($this->url('/buy'), ['player_id' => $next->id, 'idempotency_key' => 'b'])->assertConflict();
        $coins = Wallet::balance($this->owner->id);
        $this->postJson($this->url('/buy'), ['player_id' => $next->id, 'idempotency_key' => 'b', 'compensate' => true])->assertOk()->assertJsonPath('balance', 0);
        $this->assertSame($coins - $q['compensate']['coins'] - $q['doc_coins'], Wallet::balance($this->owner->id));
        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $next->id)->value('club_id'));

        // The transfers made.
        $done = $this->getJson($this->url('/done'))->assertOk()->json('transfers');
        $this->assertCount(2, $done);
    }
}
