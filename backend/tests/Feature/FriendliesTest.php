<?php

namespace Tests\Feature;

use App\League\Chemistry;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 20 B4, Sprint 24 B2] Friendlies: a real match now for 5 coins, with no effect but a little training and chemistry. */
class FriendliesTest extends TestCase
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
        // Not a fair league, where friendlies are free (its own test below).
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => '2026-10-24T10:00:00Z', 'fair_league' => false]);
        $this->mine = $this->league['my_club_id'];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(): string
    {
        return "/api/v1/leagues/{$this->league['id']}/friendlies";
    }

    private function play(int $opponent, ?string $key = null)
    {
        return $this->postJson($this->url(), ['opponent_id' => $opponent, 'idempotency_key' => $key ?? (string) Str::uuid()]);
    }

    public function test_five_coins_each_with_no_daily_limit_and_no_effect_but_training(): void
    {
        $this->assertSame(0, Wallet::balance($this->owner->id));   // the league's coins all spent on making it
        Wallet::post($this->owner->id, 'admin_gift', 22, 'gift:1');
        $view = $this->actingAs($this->owner)->getJson($this->url())->assertOk()->assertJsonPath('coins', 5)->assertJsonPath('balance', 22)
            ->assertJsonPath('left', null)->assertJsonPath('blocked', null)->json();
        $this->assertCount(3, $view['opponents']);
        $this->assertCount(1, array_filter($view['opponents'], fn ($o) => $o['recommended']));
        $opponent = $view['opponents'][0]['id'];
        $before = DB::table('players')->where('club_id', $this->mine)->get(['id', 'fitness', 'injured_matches', 'suspended_matches', 'training_progress', 'overall'])->keyBy('id');
        $balance = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $fixtures = DB::table('fixtures')->where('status', 'finished')->count();

        $played = $this->play($opponent, 'k1')->assertCreated()->assertJsonPath('balance', 17)->json('friendly');
        $this->assertSame($opponent, $played['opponent']['id']);
        $this->assertSame(5, $played['report']['coins']);
        $this->assertCount($played['goals_for'] + $played['goals_against'], $played['report']['goals']);
        $this->assertGreaterThanOrEqual(11, $played['report']['played']);
        $this->assertSame(17, Wallet::balance($this->owner->id));

        // Nothing in the game changed but the players' bars: no fitness, injury, suspension, money or table.
        $after = DB::table('players')->where('club_id', $this->mine)->get(['id', 'fitness', 'injured_matches', 'suspended_matches', 'training_progress', 'overall'])->keyBy('id');
        $grew = 0;
        foreach ($after as $id => $p) {
            $this->assertSame([$before[$id]->fitness, $before[$id]->injured_matches, $before[$id]->suspended_matches, $before[$id]->overall], [$p->fitness, $p->injured_matches, $p->suspended_matches, $p->overall]);
            $grew += $p->training_progress > $before[$id]->training_progress ? 1 : 0;
        }
        $this->assertSame($played['report']['played'], $grew);
        $this->assertSame($balance, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame($fixtures, DB::table('fixtures')->where('status', 'finished')->count());

        // The same key again: the same friendly, paid once.
        $this->play($opponent, 'k1')->assertOk()->assertJsonPath('friendly.id', $played['id']);
        $this->assertSame(17, Wallet::balance($this->owner->id));
        // No daily limit: as many as the coins pay for (three more here), then a clear refusal before playing.
        $this->play($opponent)->assertCreated();
        $this->play($opponent)->assertCreated();
        $this->play($opponent)->assertCreated()->assertJsonPath('balance', 2);
        $this->play($opponent)->assertConflict()->assertJsonPath('message', 'الودية بـ 5 كوينز، ورصيدك لا يكفي.');
        $this->assertSame(4, DB::table('friendlies')->where('club_id', $this->mine)->count());
        $this->assertSame(-20, (int) DB::table('wallet_transactions')->where('user_id', $this->owner->id)->where('type', 'friendly')->sum('amount'));
    }

    public function test_a_friendly_counts_for_the_chemistry(): void
    {
        Wallet::post($this->owner->id, 'admin_gift', 100, 'gift:1');
        config(['game.chemistry.together_matches' => 2]);
        $opponent = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->value('id');
        $this->actingAs($this->owner);
        $this->play($opponent)->assertCreated();
        $this->play($opponent)->assertCreated();
        // Two friendlies together: every pair who played in both is linked green.
        [$first, $second] = DB::table('friendlies')->where('club_id', $this->mine)->orderBy('id')->pluck('players')->map(fn ($j) => json_decode($j, true))->all();
        $this->assertGreaterThanOrEqual(11, count($first));
        $rows = array_slice(array_values(array_intersect($first, $second)), 0, 11);
        $slots = array_map(fn ($i) => ['x' => $i * 10, 'y' => 50], range(0, count($rows) - 1));
        $chem = Chemistry::of($this->mine, $rows, $slots);
        $this->assertSame(['green'], array_values(array_unique(array_column($chem['links'], 'color'))));
    }

    public function test_free_and_three_a_day_in_a_fair_league(): void
    {
        DB::table('leagues')->where('id', $this->league['id'])->update(['fair_league' => true]);
        $opponent = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->value('id');
        $this->actingAs($this->owner)->getJson($this->url())->assertJsonPath('coins', 0)->assertJsonPath('left', 3);
        $this->play($opponent)->assertCreated()->assertJsonPath('friendly.report.coins', 0);
        $this->play($opponent)->assertCreated();
        $this->play($opponent)->assertCreated()->assertJsonPath('left', 0);
        $this->play($opponent)->assertStatus(429);
        $this->assertSame(0, DB::table('wallet_transactions')->where('user_id', $this->owner->id)->where('type', 'friendly')->count());
        // A new day in Cairo: three again.
        Carbon::setTestNow('2026-10-22 22:30:00');
        $this->getJson($this->url())->assertJsonPath('left', 3)->assertJsonCount(3, 'recent');
    }

    public function test_not_before_the_match_nor_against_a_club_of_another_league(): void
    {
        $this->actingAs($this->owner);
        $this->play($this->mine)->assertNotFound();
        $other = $this->makeLeague(User::factory()->create(), ['team_count' => 4, 'starts_at' => '2026-10-24T10:00:00Z']);
        $this->actingAs($this->owner);
        $this->play($other['my_club_id'])->assertNotFound();
        // The club's match in 30 minutes: no friendly.
        $opponent = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->value('id');
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        DB::table('fixtures')->insert(['season_id' => $season, 'competition' => 'league', 'round' => 99, 'home_id' => $this->mine, 'away_id' => $opponent,
            'scheduled_at' => GameClock::now()->addMinutes(30), 'status' => 'scheduled', 'is_bye' => false, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $this->getJson($this->url())->assertJsonPath('blocked.reason', 'before_match');
        $this->play($opponent)->assertConflict();
        $this->actingAs(User::factory()->create())->getJson($this->url())->assertForbidden();
    }
}
