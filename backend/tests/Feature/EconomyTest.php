<?php

namespace Tests\Feature;

use App\Economy\Contracts;
use App\Economy\Economy;
use App\Economy\Money;
use App\League\ClubLedger;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Club money through the season [PLAN 2.7, Sprint 23]. */
class EconomyTest extends TestCase
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

    private function fixtures(string $competition = 'league')
    {
        return DB::table('fixtures')->where('competition', $competition)->where('is_bye', false)->whereNotNull('home_id')
            ->where(fn ($q) => $q->where('home_id', $this->mine)->orWhere('away_id', $this->mine))->orderBy('scheduled_at')->get();
    }

    private function assertBooksBalance(): void
    {
        foreach (DB::table('clubs')->where('league_id', $this->league['id'])->get() as $c) {
            $this->assertSame((int) $c->balance, ClubLedger::sum($c->id), "club {$c->id}");
        }
    }

    public function test_a_league_match_pays_the_gate_wages_and_bonus_once(): void
    {
        $f = $this->fixtures()->first();
        $before = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('balance', 'id');
        Economy::afterMatch($f, ['home' => 2, 'away' => 1]);
        // Published twice (a retry): nothing more.
        Economy::afterMatch($f, ['home' => 2, 'away' => 1]);

        $types = fn ($club) => DB::table('club_transactions')->where('club_id', $club)->where('reference', "fixture:{$f->id}")->pluck('amount', 'type')->all();
        $home = $types($f->home_id);
        $away = $types($f->away_id);
        $this->assertSame(4, DB::table('club_transactions')->where('club_id', $f->home_id)->where('type', 'sponsor')->count());
        $this->assertGreaterThan(0, $home['tickets']);
        $this->assertGreaterThan(0, $home['win_bonus']);
        $this->assertLessThan(0, $home['wages']);
        $this->assertLessThan(0, $away['wages']);
        $this->assertArrayNotHasKey('tickets', $away);
        $this->assertArrayNotHasKey('win_bonus', $away);
        // The loser pays the loss deduction [X14]; the away side only paid; the home side's balance moved by exactly its rows.
        $this->assertLessThan(0, $away['loss_penalty']);
        $this->assertSame((int) $before[$f->away_id] + $away['wages'] + $away['loss_penalty'], (int) DB::table('clubs')->where('id', $f->away_id)->value('balance'));
        $this->assertBooksBalance();
        // Unchosen sectors signed the steady sponsor.
        $this->assertSame(['steady'], DB::table('sponsor_contracts')->where('club_id', $f->home_id)->distinct()->pluck('offer')->all());
    }

    public function test_a_double_tap_never_charges_twice_and_a_club_in_debt_cannot_spend(): void
    {
        $b1 = ClubLedger::post($this->mine, 'wages', -1000, 'tap:1');
        $b2 = ClubLedger::post($this->mine, 'wages', -1000, 'tap:1');
        $this->assertSame($b1, $b2);
        $this->assertSame(1, DB::table('club_transactions')->where('idempotency_key', 'tap:1')->count());
        // Wages may take the club below zero; then a spend is refused.
        ClubLedger::post($this->mine, 'wages', -10_000_000, 'tap:2');
        try {
            ClubLedger::post($this->mine, 'wages', -1, 'tap:3', spend: true);
            $this->fail('a club in debt spent');
        } catch (HttpException $e) {
            $this->assertSame(409, $e->getStatusCode());
        }
        $this->assertBooksBalance();
    }

    public function test_three_league_rounds_in_debt_sell_the_dearest_player_to_the_pool(): void
    {
        ClubLedger::post($this->mine, 'wages', -(DB::table('clubs')->where('id', $this->mine)->value('balance') + 50_000), 'debt:start');
        $dearest = DB::table('players')->where('club_id', $this->mine)->orderByDesc('value')->orderBy('id')->first();
        $squad = DB::table('players')->where('club_id', $this->mine)->count();
        // Three away defeats in the league: wages, no gate, no bonus.
        [$r1, $r2, $r3] = $this->fixtures()->where('away_id', $this->mine)->take(3)->values()->all();
        foreach ([$r1, $r2] as $i => $f) {
            Economy::afterMatch($f, ['home' => 1, 'away' => 0]);
            $this->assertSame($i + 1, (int) DB::table('clubs')->where('id', $this->mine)->value('debt_rounds'));
            $this->assertSame($dearest->id, DB::table('players')->where('club_id', $this->mine)->orderByDesc('value')->orderBy('id')->value('id'));
        }
        // The coach was told once, at the first round below zero.
        $this->assertSame(1, DB::table('messages')->where('type', 'in_debt')->count());
        Economy::afterMatch($r3, ['home' => 1, 'away' => 0]);

        $this->assertNull(DB::table('players')->where('id', $dearest->id)->value('club_id'));
        $sale = DB::table('club_transactions')->where('club_id', $this->mine)->where('type', 'forced_sale')->orderBy('id')->first();
        $this->assertSame(intdiv((int) $dearest->base_value * 7000, 10000), (int) $sale->amount);
        $this->assertGreaterThanOrEqual(0, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame(0, (int) DB::table('clubs')->where('id', $this->mine)->value('debt_rounds'));
        $this->assertLessThan($squad, DB::table('players')->where('club_id', $this->mine)->count());
        $this->assertSame(1, DB::table('messages')->where('type', 'forced_sale')->count());
        $this->assertBooksBalance();
    }

    public function test_season_prizes_by_place_and_in_the_cup_once(): void
    {
        $order = DB::table('clubs')->where('league_id', $this->league['id'])->orderBy('id')->pluck('id')->all();
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        Economy::leaguePrizes($season, $order);
        Economy::leaguePrizes($season, $order);
        $prizes = DB::table('club_transactions')->where('type', 'league_prize')->orderByDesc('amount')->pluck('club_id')->all();
        $this->assertSame($order, $prizes);
        $this->assertCount(4, $prizes);

        $tie = (object) ['season_id' => $season, 'stage' => 'final'];
        Economy::cupPrizes($tie, $order[1], $order[2]);
        Economy::cupPrizes($tie, $order[1], $order[2]);
        $cup = DB::table('club_transactions')->where('type', 'cup_prize')->pluck('amount', 'club_id');
        $this->assertCount(2, $cup);
        $this->assertGreaterThan($cup[$order[2]], $cup[$order[1]]);
        $this->assertBooksBalance();
    }

    public function test_the_finance_page_and_signing_a_sponsor(): void
    {
        $page = $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/team/finance")->assertOk()
            // [Sprint 59 F1] Every field the app reads through ClubFinance (openapi.yaml).
            ->assertJsonStructure(['balance', 'can_spend', 'debt_rounds', 'debt_limit', 'wages_per_round', 'season_income', 'season_expenses',
                'season_totals', 'transactions' => ['*' => ['label', 'amount', 'balance_after', 'created_at']], 'tickets' => ['level', 'levels'],
                'sponsors' => ['*' => ['sector', 'name', 'chosen', 'offers']]])->json();
        $this->assertSame((int) DB::table('clubs')->where('id', $this->mine)->value('balance'), $page['balance']);
        $this->assertTrue($page['can_spend']);
        $this->assertCount(4, $page['sponsors']);
        $this->assertSame('ميزانية البداية', $page['transactions'][0]['label']);
        $offers = collect($page['sponsors'][0]['offers'])->keyBy('offer');
        // The steady sponsor pays most each match, the ambitious one most on a win.
        $this->assertGreaterThan($offers['ambitious']['per_match'], $offers['steady']['per_match']);
        $this->assertGreaterThan($offers['bonus']['per_win'], $offers['ambitious']['per_win']);
        $this->assertGreaterThan(0, $page['stadium']['tickets_per_match']);
        $url = "/api/v1/leagues/{$this->league['id']}/team/sponsors";
        $this->postJson($url, ['sector' => 'main', 'offer' => 'ambitious'])->assertOk()->assertJsonPath('sponsors.0.chosen', 'ambitious');
        $this->postJson($url, ['sector' => 'main', 'offer' => 'steady'])->assertConflict()->assertJsonPath('message', 'لهذا القطاع راعٍ هذا الموسم.');
        $this->postJson($url, ['sector' => 'roof', 'offer' => 'steady'])->assertJsonValidationErrors('sector');
        // After a match: its movements carry the round, and the chart has it.
        $f = $this->fixtures()->first();
        Economy::afterMatch($f, ['home' => 1, 'away' => 1]);
        $page = $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/team/finance")->assertOk()->json();
        $this->assertSame((int) $f->round, $page['transactions'][0]['round']);
        $this->assertSame((int) $f->round, $page['rounds'][0]['round']);
        $this->assertGreaterThan(0, $page['rounds'][0]['out']);
        $this->assertLessThan(0, $page['season_expenses']);

        $this->actingAs(User::factory()->create())->getJson("/api/v1/leagues/{$this->league['id']}/team/finance")->assertForbidden();
    }

    public function test_the_ticket_price_level_moves_the_crowd_and_the_gate_and_keeps_the_economy_closed(): void
    {
        // [X61] Four levels: cheap fills the stands, dear empties them; none brings much more than the usual one.
        $m = Money::fromConfig();
        foreach ([6000, 8000, 10000] as $att) {
            $usual = $m->tickets(5_000_000, 18, $att, 20000);
            foreach (['popular', 'high', 'premium'] as $level) {
                $this->assertLessThanOrEqual(intdiv($usual * 10700, 10000), $m->tickets(5_000_000, 18, $att, 20000, $level), "{$level} at {$att}");
            }
        }
        $this->assertSame([10000, 7500], $m->priced(9000, 'popular'));
        $this->assertSame([1000, 15000], $m->priced(2000, 'premium'));

        $url = "/api/v1/leagues/{$this->league['id']}/team/tickets";
        $this->actingAs($this->owner)->putJson($url, ['level' => 'free'])->assertJsonValidationErrors('level');
        $view = $this->putJson($url, ['level' => 'popular'])->assertOk()->assertJsonPath('level', 'popular')->json();
        $this->assertCount(4, $view['levels']);
        $levels = collect($view['levels'])->keyBy('level');
        $this->assertLessThan($levels['normal']['price'], $levels['popular']['price']);
        $this->assertGreaterThanOrEqual($levels['normal']['attendance_bp'], $levels['popular']['attendance_bp']);
        $this->assertLessThan($levels['normal']['attendance_bp'], $levels['premium']['attendance_bp']);
        $this->assertSame($levels['popular']['per_match'], $view['per_match']);
        $this->getJson("/api/v1/leagues/{$this->league['id']}/team/finance")->assertOk()->assertJsonPath('tickets.level', 'popular')
            ->assertJsonPath('stadium.tickets_per_match', $view['per_match']);
        $this->getJson("/api/v1/leagues/{$this->league['id']}/stadium")->assertOk()->assertJsonPath('facts.tickets.level', 'popular')
            // [Sprint 59 F1] Every field the app reads through StadiumView (openapi.yaml).
            ->assertJsonStructure(['balance', 'part_minutes', 'parts_total', 'now', 'building', 'facts' => ['parts_done', 'capacity', 'home_bp'],
                'sections' => ['*' => ['section', 'stage', 'parts', 'done', 'effects', 'next']]]);

        // The gate after a home match is the chosen level's.
        $f = $this->fixtures()->firstWhere('home_id', $this->mine);
        Economy::afterMatch($f, ['home' => 0, 'away' => 0]);
        $this->assertSame($view['per_match'], (int) DB::table('club_transactions')->where('club_id', $this->mine)->where('type', 'tickets')->value('amount'));
        $this->assertBooksBalance();
        $this->actingAs(User::factory()->create())->putJson($url, ['level' => 'high'])->assertForbidden();
    }

    public function test_contracts_show_the_wages_keep_a_cap_and_end_early_for_a_compensation(): void
    {
        // [X61 E1] Each wage is the player's share of the club's wages; the cap stops a buy; ending a contract pays half
        // of the wages left and sends the player to the market.
        $url = "/api/v1/leagues/{$this->league['id']}/team/contracts";
        $c = $this->actingAs($this->owner)->getJson($url)->assertOk()->json();
        $rounds = (int) DB::table('seasons')->where('league_id', $this->league['id'])->value('rounds');
        $this->assertSame(Money::fromConfig()->wages(Economy::squadValue($this->mine), $rounds), $c['wages_per_round']);
        $this->assertGreaterThanOrEqual($c['wages_per_round'], $c['cap_per_round']);
        $this->assertGreaterThan(0, $c['room']);
        $p = end($c['players']);
        $this->assertSame(intdiv($p['wage'] * $c['rounds_left'] * 5000, 10000), $p['release']);

        $balance = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->postJson("{$url}/{$p['id']}/release")->assertOk();
        $this->assertNull(DB::table('players')->where('id', $p['id'])->value('club_id'));
        $this->assertSame($balance - $p['release'], (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertBooksBalance();
        $this->postJson("{$url}/{$p['id']}/release")->assertNotFound();

        // No room left: a buy is refused by the cap.
        DB::table('players')->where('club_id', $this->mine)->update(['value' => DB::raw('value * 3')]);
        $this->expectException(HttpException::class);
        Contracts::assertRoom($this->mine, 1);
    }

    public function test_the_numbers_scale_with_the_league(): void
    {
        $m = Money::fromConfig();
        // A 60M squad over 38 rounds: 3% a season.
        $this->assertSame(intdiv(60_000_000 * 300, 10000 * 38), $m->wages(60_000_000, 38));
        // A home match at full attendance: sponsors (all steady) and tickets add up to about the home share.
        $scale = 60_000_000;
        $sponsors = array_sum(array_map(fn ($s) => $m->sponsor($scale, 38, $s, 'steady', false), array_keys(config('game.economy.sectors'))));
        $full = $sponsors + $m->tickets($scale, 38, 10000);
        $this->assertEqualsWithDelta($m->homeMatch($scale, 38), $full, 30_000);
        $this->assertSame(6000, $m->attendance(10, 10, 90));
        $this->assertSame(10000, $m->attendance(90, 10, 90));
    }

    /** [X14] A win pays the most, a draw less, and a loss takes money away: all from config. */
    public function test_the_result_money_from_a_win_down_to_a_loss(): void
    {
        $money = new Money(config('game.economy'));
        $scale = 10_000_000;
        $this->assertSame(8_000, $money->resultBonus($scale, 2, 1));
        $this->assertSame(3_000, $money->resultBonus($scale, 1, 1));
        $this->assertSame(-2_000, $money->resultBonus($scale, 0, 3));
    }
}
