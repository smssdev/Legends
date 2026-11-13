<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Market\Auctions;
use App\Models\User;
use App\Store\Chests;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 50 M18, M19, M21] Auctions, the release clause, the talk with a computer club, and the store's chests. */
class MarketDealsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $coach;

    private array $league;

    private int $mine;

    private int $theirs;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
        $this->coach = $this->approvedCoach($this->owner, $this->league);
        $this->theirs = $this->botClub($this->league['id']);
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->theirs}/claim")->assertCreated();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}{$path}";
    }

    private function cheapest(int $club): object
    {
        return DB::table('players')->where('club_id', $club)->orderBy('value')->orderBy('id')->first();
    }

    public function test_an_auction_goes_to_the_highest_bid_that_can_be_paid(): void
    {
        $p = $this->cheapest($this->mine);
        $value = (int) $p->value;
        $this->actingAs($this->owner)->postJson($this->url('/transfers/listings'), ['player_id' => $p->id, 'price' => $value, 'auction_minutes' => 45])->assertUnprocessable();
        $this->postJson($this->url('/transfers/listings'), ['player_id' => $p->id, 'price' => $value, 'auction_minutes' => 30])->assertOk();
        // No outside buyer for an auction.
        $this->assertNull(DB::table('transfer_listings')->where('player_id', $p->id)->value('sells_at'));

        $bid = fn (User $u, int $amount) => $this->actingAs($u)->postJson($this->url("/auctions/{$p->id}/bids"), ['amount' => $amount, 'idempotency_key' => uniqid('b', true)]);
        $bid($this->owner, $value)->assertConflict();                    // not on his own
        $bid($this->coach, $value - 1)->assertUnprocessable();          // under the opening price
        $bid($this->coach, $value)->assertOk()->assertJsonPath('auction.leading', true);
        $next = Auctions::next($value, $value, $value);
        $bid($this->coach, $next)->assertConflict();                     // he leads already
        $this->assertSame($next, $this->actingAs($this->coach)->getJson($this->url('/auctions'))
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['minutes', 'auctions' => ['*' => ['player_id', 'name', 'position', 'age', 'overall', 'value', 'club_id', 'club', 'opening', 'top', 'bids', 'next', 'max', 'mine', 'leading', 'ends_at']]])
            ->json('auctions.0.next'));
        $bid($this->coach, $value * 3)->assertConflict();

        // The end comes; the deal goes through the coaches' path.
        Carbon::setTestNow(GameClock::now()->addMinutes(31));
        $this->artisan('market:renew')->assertSuccessful();
        $this->assertSame($this->theirs, (int) DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertFalse(DB::table('transfer_listings')->where('player_id', $p->id)->exists());
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'auction_sold')->count());
        foreach ([$this->mine, $this->theirs] as $c) {
            $this->assertSame((int) DB::table('clubs')->where('id', $c)->value('balance'), ClubLedger::sum($c));
        }
    }

    public function test_a_late_bid_moves_the_end(): void
    {
        $p = $this->cheapest($this->mine);
        $this->actingAs($this->owner)->postJson($this->url('/transfers/listings'), ['player_id' => $p->id, 'price' => (int) $p->value, 'auction_minutes' => 30])->assertOk();
        Carbon::setTestNow(GameClock::now()->addMinutes(29)->addSeconds(30));
        $this->actingAs($this->coach)->postJson($this->url("/auctions/{$p->id}/bids"), ['amount' => (int) $p->value, 'idempotency_key' => 'late'])->assertOk();
        $ends = Carbon::parse(DB::table('transfer_listings')->where('player_id', $p->id)->value('auction_ends_at'), 'UTC');
        $this->assertTrue($ends->gte(GameClock::now()->addSeconds((int) config('game.auctions.extend_seconds') - 1)));
        // With bids it cannot be withdrawn.
        $this->actingAs($this->owner)->deleteJson($this->url("/transfers/listings/{$p->id}"))->assertConflict();
    }

    public function test_the_release_clause_takes_a_coachs_player_without_his_answer(): void
    {
        $p = $this->cheapest($this->theirs);
        $clause = intdiv((int) $p->value * (int) config('game.economy.release_clause_bp'), 10000);
        $this->actingAs($this->owner)->getJson($this->url("/release/{$p->id}"))->assertOk()->assertJsonPath('clause', $clause)
            // [Sprint 59 F1] The fields the app reads through its generated model (LeaguesReleaseByPlayerAnswer).
            ->assertJsonStructure(['player_id', 'clause', 'club' => ['id', 'name'], 'can', 'why']);
        $before = (int) DB::table('clubs')->where('id', $this->theirs)->value('balance');
        $this->postJson($this->url("/release/{$p->id}"), ['idempotency_key' => 'r1'])->assertOk()->assertJsonPath('price', $clause);
        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertSame($before + $clause, (int) DB::table('clubs')->where('id', $this->theirs)->value('balance'));
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->coach->id)->where('type', 'release_clause')->count());
        // A computer club's player is not taken this way.
        $bot = $this->cheapest($this->botClub($this->league['id']));
        $this->getJson($this->url("/release/{$bot->id}"))->assertConflict();
    }

    public function test_a_computer_club_meets_the_coach_halfway_and_never_under_its_floor(): void
    {
        // A computer club keeps 18 players: give it two more to sell.
        $bot = $this->botClub($this->league['id']);
        DB::table('players')->where('league_id', $this->league['id'])->whereNull('club_id')->orderBy('id')->limit(2)->update(['club_id' => $bot, 'in_pool' => false]);
        $p = $this->cheapest($bot);
        $url = $this->url("/negotiations/{$p->id}");
        $ask = $this->actingAs($this->owner)->getJson($url)->assertOk()
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['player_id', 'price', 'ask', 'round', 'rounds', 'status', 'expires_at'])->json('ask');
        $floor = intdiv((int) $p->value * (int) config('game.negotiation.floor_bp'), 10000);
        $offer = $floor;
        $res = $this->postJson($url, ['amount' => $offer, 'idempotency_key' => 'n1'])->assertOk()->json();
        $this->assertSame(max($floor, intdiv($ask + $offer, 2)), $res['ask']);
        $this->assertFalse($res['bought']);
        $res = $this->postJson($url, ['amount' => $res['ask'], 'idempotency_key' => 'n2'])->assertOk()->json();
        $this->assertTrue($res['bought']);
        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $p->id)->value('club_id'));

        // An insult ends the talk for the day.
        $q = DB::table('players')->where('club_id', $this->botClub($this->league['id']))->orderBy('value')->skip(1)->first();
        $this->postJson($this->url("/negotiations/{$q->id}"), ['amount' => 1, 'idempotency_key' => 'n3'])->assertJsonPath('status', 'closed');
        $this->postJson($this->url("/negotiations/{$q->id}"), ['amount' => (int) $q->value * 2, 'idempotency_key' => 'n4'])->assertConflict();
    }

    public function test_a_chest_shows_its_odds_costs_its_coins_and_gives_one_reward(): void
    {
        $chests = $this->actingAs($this->owner)->getJson($this->url('/chests'))->assertOk()
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['chests' => ['*' => ['chest', 'coins', 'odds' => ['*' => ['reward', 'amount', 'pct_bp']]]]])->json('chests');
        $this->assertSame(['bronze', 'silver', 'legend'], array_column($chests, 'chest'));
        $this->assertSame(10000, array_sum(array_column($chests[0]['odds'], 'pct_bp')));
        // Coins are spent outside a fair league only.
        DB::table('leagues')->where('id', $this->league['id'])->update(['fair_league' => false]);
        Wallet::post($this->owner->id, 'admin_gift', 500, 'gift:chest');
        $coins = Wallet::balance($this->owner->id);
        $opened = $this->postJson($this->url('/chests/bronze/open'), ['idempotency_key' => 'c1'])->assertOk()
            ->assertJsonStructure(['opened' => ['chest', 'reward', 'amount']])->json('opened');   // [Sprint 59 F1] what the app reads
        $this->assertContains($opened['reward'], Chests::REWARDS);
        $back = $opened['reward'] === 'coins' ? $opened['amount'] : 0;
        $this->assertSame($coins - (int) config('game.chests.bronze.coins') + $back, Wallet::balance($this->owner->id));
        // One key, one chest.
        $this->postJson($this->url('/chests/bronze/open'), ['idempotency_key' => 'c1'])->assertOk()->assertJsonPath('opened', $opened);
        $this->assertSame(1, DB::table('chest_openings')->count());
        $this->postJson($this->url('/chests/golden/open'), ['idempotency_key' => 'c2'])->assertNotFound();
        // The roll lands by the weights in order.
        $table = config('game.chests.bronze.table');
        $this->assertSame($table[0]['reward'], Chests::pick($table, 0)['reward']);
        $this->assertSame($table[1]['reward'], Chests::pick($table, (int) $table[0]['weight'])['reward']);
    }
}
