<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\League\Integrity;
use App\League\Standings;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X28] The integrity system: bribes and the VAR, spies and double agents, the FA and the scandal. */
class IntegrityTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $rival;

    private array $league;

    private object $fixture;

    private int $mine;

    private int $theirs;

    private string $url;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'integrity' => true, 'fair_league' => false, 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
        $this->fixture = DB::table('fixtures')->where('competition', 'league')->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $this->mine)->orWhere('away_id', $this->mine))->orderBy('scheduled_at')->first();
        $this->theirs = $this->fixture->home_id === $this->mine ? $this->fixture->away_id : $this->fixture->home_id;
        // The opponent has a coach too.
        $this->rival = User::factory()->create();
        DB::table('clubs')->where('id', $this->theirs)->update(['user_id' => $this->rival->id]);
        DB::table('league_memberships')->insert(['league_id' => $this->league['id'], 'season_id' => $this->fixture->season_id, 'user_id' => $this->rival->id,
            'club_id' => $this->theirs, 'joined_at' => GameClock::now(), 'last_active_at' => GameClock::now(), 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        foreach ([$this->owner, $this->rival] as $u) {
            Wallet::post($u->id, 'daily', 300, "gift:{$u->id}");
        }
        $this->url = "/api/v1/leagues/{$this->league['id']}/integrity";
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function balance(int $club): int
    {
        return (int) DB::table('clubs')->where('id', $club)->value('balance');
    }

    public function test_a_bribe_costs_money_and_coins_and_only_where_the_owner_allows_it(): void
    {
        $this->actingAs($this->owner);
        $view = $this->getJson($this->url)->assertOk()->json();
        $this->assertTrue($view['on']);
        $this->assertSame($this->fixture->id, $view['fixture']['id']);
        $before = $this->balance($this->mine);
        $this->postJson("{$this->url}/bribe", ['fixture_id' => $this->fixture->id])->assertOk()->assertJsonPath('bribe.paid', true);
        $this->assertSame($before - $view['bribe']['money'], $this->balance($this->mine));
        $this->assertSame(300 - $view['bribe']['extra']['amount'], Wallet::balance($this->owner->id));
        $this->assertSame(ClubLedger::sum($this->mine), $this->balance($this->mine));
        $this->postJson("{$this->url}/bribe", ['fixture_id' => $this->fixture->id])->assertStatus(409);

        DB::table('leagues')->where('id', $this->league['id'])->update(['integrity' => false]);
        $this->actingAs($this->rival)->postJson("{$this->url}/bribe", ['fixture_id' => $this->fixture->id])->assertStatus(409);
    }

    public function test_the_var_catches_one_in_five_and_otherwise_the_referee_leans(): void
    {
        DB::table('bribes')->insert(['fixture_id' => $this->fixture->id, 'club_id' => $this->mine, 'money' => 1, 'created_at' => GameClock::now()]);
        $side = $this->fixture->home_id === $this->mine ? 'home' : 'away';
        $caught = 0;
        foreach (range(1, 500) as $seed) {
            DB::table('bribes')->update(['outcome' => null]);
            DB::table('clubs')->where('id', $this->mine)->update(['morale' => 70]);
            $leans = Integrity::kickOff($this->fixture, $seed);
            $outcome = DB::table('bribes')->value('outcome');
            $this->assertSame($outcome === 'clean', $leans[$side]);
            if ($outcome === 'var') {
                $caught++;
                $this->assertSame(60, (int) DB::table('clubs')->where('id', $this->mine)->value('morale'));
            }
        }
        $this->assertGreaterThan(70, $caught);
        $this->assertLessThan(130, $caught);
        // Decided once: a second call changes nothing.
        $this->assertSame(['home' => false, 'away' => false], Integrity::kickOff($this->fixture, 1));
    }

    public function test_a_spy_finds_the_bribe_and_the_fa_punishes_with_a_scandal(): void
    {
        $this->actingAs($this->owner)->postJson("{$this->url}/bribe", ['fixture_id' => $this->fixture->id])->assertOk();
        $this->actingAs($this->rival)->postJson("/api/v1/leagues/{$this->league['id']}/spy")->assertOk()->assertJsonPath('report.bribed', true);
        $proof = $this->getJson($this->url)->json('proofs.0');
        $this->assertFalse($proof['filed']);

        $balance = $this->balance($this->mine);
        $morale = (int) DB::table('clubs')->where('id', $this->mine)->value('morale');
        $res = $this->postJson("{$this->url}/spies/{$proof['spy_report_id']}/accuse")->assertOk()->json();
        $this->assertSame(intdiv($balance * 3000, 10000), $res['verdict']['fine']);
        $this->assertSame($balance - $res['verdict']['fine'], $this->balance($this->mine));
        $this->assertSame(ClubLedger::sum($this->mine), $this->balance($this->mine));
        $this->assertSame($morale - 15, (int) DB::table('clubs')->where('id', $this->mine)->value('morale'));
        $this->assertSame(2500, (int) DB::table('clubs')->where('id', $this->mine)->value('attendance_cut_bp'));
        $this->postJson("{$this->url}/spies/{$proof['spy_report_id']}/accuse")->assertStatus(409);

        // The headline for everyone in the league, and the points off in the table.
        $this->assertStringContainsString('فضيحة الموسم', $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}")->json('league.headlines.0.text'));
        $this->assertSame(-3, collect($this->getJson("/api/v1/leagues/{$this->league['id']}/standings")->json('table'))->firstWhere('id', $this->mine)['points']);
        $this->assertSame($this->mine, Standings::order($this->fixture->season_id)[3]);

        // Out of the market for a day.
        $player = DB::table('players')->where('club_id', $this->mine)->value('id');
        $this->postJson("/api/v1/leagues/{$this->league['id']}/market/sell", ['player_id' => $player, 'idempotency_key' => 'k1'])->assertStatus(409)
            ->assertJsonPath('message', fn ($m) => str_contains($m, 'محظور'));
        Carbon::setTestNow(GameClock::now()->addHours(25));
        $this->assertNull(rescue(fn () => Integrity::assertMarket($this->mine), false, false));
    }

    public function test_a_spy_seen_can_be_turned_into_a_double_agent(): void
    {
        $this->actingAs($this->owner)->postJson("{$this->url}/bribe", ['fixture_id' => $this->fixture->id])->assertOk();
        $this->actingAs($this->rival)->postJson("/api/v1/leagues/{$this->league['id']}/spy")->assertOk();
        $spy = (int) DB::table('spy_reports')->value('id');
        $real = json_decode(DB::table('spy_reports')->value('report'), true);

        // Without a lawyer of four stars or a security check, the spies are not seen.
        $this->actingAs($this->owner);
        $this->assertSame([], $this->getJson($this->url)->json('spies_on_me'));
        $this->postJson("{$this->url}/spies/{$spy}/turn")->assertStatus(403);
        $this->postJson("{$this->url}/security", ['fixture_id' => $this->fixture->id])->assertOk()->assertJsonPath('security.sees', true);
        $this->assertSame($spy, $this->getJson($this->url)->json('spies_on_me.0.id'));
        $this->postJson("{$this->url}/spies/{$spy}/turn")->assertOk()->assertJsonPath('spies_on_me.0.turned', true);

        // The rival's report is now a fake board, with no bribe in it: nothing to take to the FA.
        $fake = $this->actingAs($this->rival)->getJson("/api/v1/leagues/{$this->league['id']}/spy")
            // [Sprint 59 F1] The fields the app reads through SpyView (openapi.yaml).
            ->assertJsonStructure(['cost', 'currency', 'fixture', 'report'])->json('report');
        $this->assertNotSame($real['formation'], $fake['formation']);
        $this->assertNotSame($real['tactics']['plan'], $fake['tactics']['plan']);
        $this->assertFalse($fake['bribed']);
        $this->assertSame([], $this->getJson($this->url)->json('proofs'));
        $this->postJson("{$this->url}/spies/{$spy}/accuse")->assertStatus(422);
    }
}
