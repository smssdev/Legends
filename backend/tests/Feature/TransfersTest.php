<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Market\Loans;
use App\Market\SellOn;
use App\Market\Transfers;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Trades between coaches and the limits against collusion [PLAN 2.7, Sprint 25]. */
class TransfersTest extends TestCase
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
        $this->owner = User::factory()->create(['name' => 'سليمان']);
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
        // [X105] The squads of 18 here test the other limits; each line's floor is SquadFloorTest's.
        config(['game.economy.min_lines' => []]);
        $this->coach = $this->approvedCoach($this->owner, $this->league);
        $this->theirs = $this->botClub($this->league['id']);
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->theirs}/claim")->assertCreated();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path = ''): string
    {
        return "/api/v1/leagues/{$this->league['id']}/transfers{$path}";
    }

    /** A club's players, cheapest first. */
    private function players(int $club)
    {
        return DB::table('players')->where('club_id', $club)->orderBy('value')->orderBy('id')->get();
    }

    private function offer(User $by, int $to, array $in, array $out = [], int $money = 0)
    {
        return $this->actingAs($by)->postJson($this->url('/offers'), ['to_club_id' => $to, 'in' => $in, 'out' => $out, 'money' => $money, 'idempotency_key' => uniqid()]);
    }

    private function assertBooks(): void
    {
        foreach ([$this->mine, $this->theirs] as $c) {
            $this->assertSame((int) DB::table('clubs')->where('id', $c)->value('balance'), ClubLedger::sum($c));
        }
    }

    public function test_a_full_swap_between_two_coaches(): void
    {
        $want = $this->players($this->theirs)->first();
        $give = $this->players($this->mine)->first();
        $money = 200_000;
        $id = $this->offer($this->owner, $this->theirs, [$want->id], [$give->id], $money)->assertCreated()->json('offer.id');
        // The other coach hears of it, and only he can accept it.
        $this->assertSame(1, DB::table('messages')->where('type', 'offer_received')->where('user_id', $this->coach->id)->count());
        $this->actingAs($this->owner)->postJson($this->url("/offers/{$id}/accept"))->assertNotFound();
        $before = DB::table('clubs')->whereIn('id', [$this->mine, $this->theirs])->pluck('balance', 'id');
        $this->actingAs($this->coach)->postJson($this->url("/offers/{$id}/accept"))->assertOk()->assertJsonPath('offer.status', 'accepted');

        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $want->id)->value('club_id'));
        $this->assertSame($this->theirs, (int) DB::table('players')->where('id', $give->id)->value('club_id'));
        $this->assertSame((int) $before[$this->mine] - $money, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame((int) $before[$this->theirs] + $money, (int) DB::table('clubs')->where('id', $this->theirs)->value('balance'));
        $this->assertSame(2, DB::table('player_moves')->where('offer_id', $id)->count());
        $this->assertSame(1, DB::table('messages')->where('type', 'offer_accepted')->where('user_id', $this->owner->id)->count());
        // Accepted once: again is refused.
        $this->postJson($this->url("/offers/{$id}/accept"))->assertConflict();
        $this->assertBooks();
    }

    public function test_the_price_stays_between_half_and_double_the_value(): void
    {
        $want = $this->players($this->theirs)->first();
        $this->offer($this->owner, $this->theirs, [$want->id], [], intdiv((int) $want->value, 2) - 1)->assertStatus(422);
        $this->offer($this->owner, $this->theirs, [$want->id], [], (int) $want->value * 2 + 1)->assertStatus(422);
        $this->offer($this->owner, $this->theirs, [$want->id], [], (int) $want->value)->assertCreated();
        // The transfer list too.
        $mine = $this->players($this->mine)->first();
        $this->actingAs($this->owner)->postJson($this->url('/listings'), ['player_id' => $mine->id, 'price' => (int) $mine->value * 3])->assertStatus(422);
        $this->postJson($this->url('/listings'), ['player_id' => $mine->id, 'price' => (int) $mine->value])->assertOk()
            ->assertJsonPath('listings.0.player.id', $mine->id)->assertJsonPath('listings.0.mine', true);
    }

    public function test_a_player_does_not_move_twice_between_the_same_two_clubs_in_a_season(): void
    {
        $want = $this->players($this->theirs)->first();
        $id = $this->offer($this->owner, $this->theirs, [$want->id], [], (int) $want->value)->json('offer.id');
        $this->actingAs($this->coach)->postJson($this->url("/offers/{$id}/accept"))->assertOk();
        // He wants him back.
        $this->offer($this->coach, $this->mine, [$want->id], [], (int) $want->value)->assertConflict()
            ->assertJsonPath('message', 'انتقل هذا اللاعب بين الناديين هذا الموسم، فلا ينتقل بينهما مرة أخرى.');
    }

    public function test_what_is_paid_beyond_value_between_two_clubs_has_a_season_cap(): void
    {
        // A fair sale moves its money whatever it is: its value is paid, nothing beyond.
        [$a, $b, $c] = $this->players($this->theirs)->take(3)->values()->all();
        $fair = $this->offer($this->owner, $this->theirs, [$a->id], [], (int) $a->value)->assertCreated()->json('offer.id');
        $this->actingAs($this->coach)->postJson($this->url("/offers/{$fair}/accept"))->assertOk();
        $this->assertSame(0, (int) DB::table('transfer_offers')->where('id', $fair)->value('excess'));
        // Overpaying moves money: 600,000 over value passes, then 200,000 more goes beyond the 750,000 cap.
        $over = $this->offer($this->owner, $this->theirs, [$b->id], [], (int) $b->value + 600_000)->assertCreated()->json('offer.id');
        $this->actingAs($this->coach)->postJson($this->url("/offers/{$over}/accept"))->assertOk();
        $message = $this->offer($this->owner, $this->theirs, [$c->id], [], (int) $c->value + 200_000)->assertConflict()->json('message');
        $this->assertStringContainsString('750,000', $message);
        $this->assertStringContainsString('150,000', $message);
        // Overpaid back the other way, it nets down.
        $back = $this->players($this->mine)->first();
        $this->offer($this->coach, $this->mine, [$back->id], [], (int) $back->value + 200_000)->assertCreated();
    }

    public function test_countering_and_rejecting(): void
    {
        $want = $this->players($this->theirs)->first();
        $id = $this->offer($this->owner, $this->theirs, [$want->id], [], (int) $want->value)->json('offer.id');
        // The coach asks for more, and a player of mine.
        $extra = $this->players($this->mine)->first();
        $counter = $this->actingAs($this->coach)->postJson($this->url("/offers/{$id}/counter"), ['in' => [$extra->id], 'out' => [$want->id], 'money' => 0, 'idempotency_key' => 'c1'])
            ->assertCreated()->json('offer');
        $this->assertSame('countered', DB::table('transfer_offers')->where('id', $id)->value('status'));
        $this->assertSame($id, $counter['counter_of']);
        $this->assertSame(1, DB::table('messages')->where('type', 'offer_countered')->where('user_id', $this->owner->id)->count());
        // The owner sees it as incoming and turns it down.
        $seen = collect($this->actingAs($this->owner)->getJson($this->url())->assertOk()
            // [Sprint 59 F1] Every field Transfers and TransferOffer require in openapi.yaml (the app reads them through it).
            ->assertJsonStructure(['closed', 'fair' => ['min_bp', 'max_bp'], 'pair_cap', 'listings', 'clubs' => ['*' => ['id', 'name', 'code']],
                'offers' => ['*' => ['id', 'status', 'money', 'from' => ['id', 'name'], 'to' => ['id', 'name'], 'incoming', 'expires_at',
                    'in' => ['*' => ['id', 'name', 'position', 'line', 'age', 'overall', 'value']], 'out']]])
            ->json('offers'))->firstWhere('id', $counter['id']);
        $this->assertTrue($seen['incoming']);
        $this->postJson($this->url("/offers/{$counter['id']}/reject"))->assertOk()->assertJsonPath('offer.status', 'rejected');
        $this->assertSame(1, DB::table('messages')->where('type', 'offer_rejected')->where('user_id', $this->coach->id)->count());
    }

    public function test_an_offer_dies_when_its_player_leaves_and_when_its_time_runs_out(): void
    {
        // An outfield player: the pool sale below may not leave fewer than two keepers.
        $want = $this->players($this->theirs)->first(fn ($p) => DB::table('master_players')->where('id', $p->master_player_id)->value('line') !== 'gk');
        $id = $this->offer($this->owner, $this->theirs, [$want->id], [], (int) $want->value)->json('offer.id');
        $this->actingAs($this->coach)->postJson($this->url('/listings'), ['player_id' => $want->id, 'price' => (int) $want->value])->assertOk();
        // The coach sells him to the pool instead: the offer and the listing go.
        $this->postJson("/api/v1/leagues/{$this->league['id']}/market/sell", ['player_id' => $want->id, 'idempotency_key' => 'x'])->assertOk();
        $this->assertSame('cancelled', DB::table('transfer_offers')->where('id', $id)->value('status'));
        $this->assertSame(0, DB::table('transfer_listings')->count());
        $this->assertSame(1, DB::table('messages')->where('type', 'offer_cancelled')->where('user_id', $this->owner->id)->count());

        $other = $this->players($this->theirs)->first();
        $late = $this->offer($this->owner, $this->theirs, [$other->id], [], (int) $other->value)->json('offer.id');
        Carbon::setTestNow(GameClock::now()->addHours(49));
        $this->assertSame(1, Transfers::expire());
        $this->assertSame('expired', DB::table('transfer_offers')->where('id', $late)->value('status'));
    }

    public function test_a_sell_on_clause_pays_the_first_seller_a_share_of_the_next_sale_once(): void
    {
        // [X62] The coach buys my player promising me 15% of his next sale; he sells him on, and I get it.
        $p = $this->players($this->mine)->first();
        $price = (int) $p->value;
        $this->actingAs($this->coach)->postJson($this->url('/offers'), ['to_club_id' => $this->mine, 'money' => $price, 'in' => [$p->id], 'sell_on_bp' => 9000, 'idempotency_key' => 'so0'])->assertStatus(422);
        $id = $this->postJson($this->url('/offers'), ['to_club_id' => $this->mine, 'money' => $price, 'in' => [$p->id], 'sell_on_bp' => 1500, 'idempotency_key' => 'so1'])->assertCreated()->json('offer.id')
            ?? DB::table('transfer_offers')->where('idempotency_key', "offer:{$this->theirs}:so1")->value('id');
        $this->actingAs($this->owner)->postJson($this->url("/offers/{$id}/accept"))->assertOk();
        $this->assertSame(1500, (int) DB::table('players')->where('id', $p->id)->value('sell_on_bp'));
        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $p->id)->value('sell_on_club_id'));

        $mine = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->assertSame(intdiv(1000000 * 1500, 10000), SellOn::settle($this->theirs, $p->id, 1000000, 'test-sale'));
        $this->assertSame($mine + 150000, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame(0, SellOn::settle($this->theirs, $p->id, 1000000, 'test-sale-2'));
        $this->assertBooks();
    }

    public function test_a_loan_moves_the_player_for_its_rounds_and_sends_him_home(): void
    {
        // [X61 E2] The coach asks my player for two rounds and a fee; I accept; after the rounds he is back.
        $p = $this->players($this->mine)->first();
        $fee = intdiv((int) $p->value, 10);
        $this->actingAs($this->coach)->postJson($this->url('/loans'), ['player_id' => $p->id, 'rounds' => 9, 'fee' => $fee])->assertStatus(422);
        $this->postJson($this->url('/loans'), ['player_id' => $p->id, 'rounds' => 2, 'fee' => (int) $p->value])->assertStatus(422);
        $loans = $this->postJson($this->url('/loans'), ['player_id' => $p->id, 'rounds' => 2, 'fee' => $fee])->assertOk()
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['max_rounds', 'max_fee_bp', 'loans' => ['*' => ['id', 'status', 'mine', 'player' => ['id', 'name', 'position'], 'owner', 'borrower', 'rounds', 'fee', 'until_round']]])
            ->json('loans');
        $this->assertSame('pending', $loans[0]['status']);
        $this->postJson($this->url('/loans'), ['player_id' => $p->id, 'rounds' => 1, 'fee' => 0])->assertConflict();
        $this->postJson($this->url("/loans/{$loans[0]['id']}/answer"), ['accept' => true])->assertNotFound();

        $mine = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->actingAs($this->owner)->postJson($this->url("/loans/{$loans[0]['id']}/answer"), ['accept' => true])->assertOk()->assertJsonPath('loans.0.status', 'active');
        $this->assertSame($this->theirs, (int) DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertSame($mine + $fee, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertBooks();

        $season = DB::table('seasons')->where('league_id', $this->league['id'])->first();
        $this->assertSame(0, Loans::returnDue($season->id));
        DB::table('seasons')->where('id', $season->id)->update(['rounds_played' => (int) $season->rounds_played + 2]);
        $this->assertSame(1, Loans::returnDue($season->id));
        $this->assertSame($this->mine, (int) DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertSame('returned', DB::table('player_loans')->where('id', $loans[0]['id'])->value('status'));
        $this->assertSame(0, Loans::returnDue($season->id));
    }

    public function test_a_bot_is_bought_from_in_the_market_not_by_offer(): void
    {
        $bot = $this->botClub($this->league['id']);
        $this->offer($this->owner, $bot, [$this->players($bot)->first()->id], [], 1_000_000)->assertConflict()
            ->assertJsonPath('message', 'هذا نادي حاسوب: اشترِ منه من السوق.');
        $this->offer($this->owner, $this->theirs, [$this->players($this->mine)->first()->id], [], 0)->assertConflict();
    }
}
