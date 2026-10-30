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

/** [Sprint 20 B4, Sprint 24 B2] Friendlies: a real match now for 5 coins, with no effect but fitness, a little training and chemistry. */
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

    public function test_five_coins_each_with_no_limit_and_no_effect_but_fitness_and_training(): void
    {
        $this->assertSame(0, Wallet::balance($this->owner->id));   // the league's coins all spent on making it
        Wallet::post($this->owner->id, 'admin_gift', 22, 'gift:1');
        $view = $this->actingAs($this->owner)->getJson($this->url())->assertOk()->assertJsonPath('coins', 5)->assertJsonPath('balance', 22)
            ->assertJsonPath('fitness', 5)->assertJsonPath('blocked', null)->json();
        $this->assertCount(3, $view['opponents']);
        $this->assertCount(1, array_filter($view['opponents'], fn ($o) => $o['recommended']));
        $opponent = $view['opponents'][0]['id'];
        // Tired players, so the friendly's fitness shows (one near the top: never past 100).
        DB::table('players')->where('club_id', $this->mine)->update(['fitness' => 80]);
        DB::table('players')->where('club_id', $this->mine)->orderBy('id')->limit(1)->update(['fitness' => 98]);
        $before = DB::table('players')->where('club_id', $this->mine)->get(['id', 'fitness', 'injured_matches', 'suspended_matches', 'training_progress', 'overall'])->keyBy('id');
        $balance = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $fixtures = DB::table('fixtures')->where('status', 'finished')->count();

        $played = $this->play($opponent, 'k1')->assertCreated()->assertJsonPath('balance', 17)->json('friendly');
        $this->assertSame($opponent, $played['opponent']['id']);
        $this->assertSame(5, $played['report']['coins']);
        $this->assertCount($played['goals_for'] + $played['goals_against'], $played['report']['goals']);
        $this->assertGreaterThanOrEqual(11, $played['report']['played']);
        $this->assertSame(17, Wallet::balance($this->owner->id));

        // Nothing in the game changed but the fitness and the bars of those who played: no injury, suspension, money or table.
        $after = DB::table('players')->where('club_id', $this->mine)->get(['id', 'fitness', 'injured_matches', 'suspended_matches', 'training_progress', 'overall'])->keyBy('id');
        $grew = 0;
        foreach ($after as $id => $p) {
            $this->assertSame([$before[$id]->injured_matches, $before[$id]->suspended_matches, $before[$id]->overall], [$p->injured_matches, $p->suspended_matches, $p->overall]);
            $tookPart = $p->training_progress > $before[$id]->training_progress;
            $grew += $tookPart ? 1 : 0;
            $this->assertSame($tookPart ? min(100, $before[$id]->fitness + 5) : $before[$id]->fitness, (int) $p->fitness);
        }
        $this->assertSame($played['report']['played'], $grew);
        $this->assertSame($balance, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame($fixtures, DB::table('fixtures')->where('status', 'finished')->count());

        // The same key again: the same friendly, paid once.
        $this->play($opponent, 'k1')->assertOk()->assertJsonPath('friendly.id', $played['id']);
        $this->assertSame(17, Wallet::balance($this->owner->id));
        // No limit: as many as the coins pay for (three more here), then a clear refusal before playing. [Sprint 27 X1]
        // Each club once a day: the other two today, the first again tomorrow.
        $this->play($view['opponents'][1]['id'])->assertCreated();
        $this->play($view['opponents'][2]['id'])->assertCreated();
        Carbon::setTestNow('2026-10-23 10:00:00');
        $this->play($opponent)->assertCreated()->assertJsonPath('balance', 2);
        $this->play($view['opponents'][1]['id'])->assertConflict()->assertJsonPath('message', 'الودية بـ 5 كوينز، ورصيدك لا يكفي.');
        $this->assertSame(4, DB::table('friendlies')->where('club_id', $this->mine)->count());
        $this->assertSame(-20, (int) DB::table('wallet_transactions')->where('user_id', $this->owner->id)->where('type', 'friendly')->sum('amount'));
    }

    public function test_a_friendly_counts_for_the_chemistry(): void
    {
        Wallet::post($this->owner->id, 'admin_gift', 100, 'gift:1');
        config(['game.chemistry.together_matches' => 2]);
        [$opponent, $another] = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->pluck('id')->all();
        $this->actingAs($this->owner);
        $this->play($opponent)->assertCreated();
        $this->play($another)->assertCreated();
        // Two friendlies together: every pair who played in both is linked green.
        [$first, $second] = DB::table('friendlies')->where('club_id', $this->mine)->orderBy('id')->pluck('players')->map(fn ($j) => json_decode($j, true))->all();
        $this->assertGreaterThanOrEqual(11, count($first));
        $rows = array_slice(array_values(array_intersect($first, $second)), 0, 11);
        $slots = array_map(fn ($i) => ['x' => $i * 10, 'y' => 50], range(0, count($rows) - 1));
        $chem = Chemistry::of($this->mine, $rows, $slots);
        $this->assertSame(['green'], array_values(array_unique(array_column($chem['links'], 'color'))));
    }

    public function test_five_coins_in_a_fair_league_too_and_never_against_the_season_cap(): void
    {
        DB::table('leagues')->where('id', $this->league['id'])->update(['fair_league' => true]);
        config(['game.premium.season_cap' => 10]);
        Wallet::post($this->owner->id, 'admin_gift', 100, 'gift:1');
        $opponents = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->pluck('id')->all();
        $this->actingAs($this->owner)->getJson($this->url())->assertJsonPath('coins', 5);
        // Four friendlies: 20 coins, over a cap of 10, and the cap left whole for the league's spends (each club once a
        // day [Sprint 27 X1]: the three today, the first again tomorrow).
        foreach ([...$opponents, $opponents[0]] as $n => $opponent) {
            if ($n === 3) {
                Carbon::setTestNow('2026-10-23 10:00:00');
            }
            $this->play($opponent)->assertCreated()->assertJsonPath('friendly.report.coins', 5);
        }
        $this->assertSame(80, Wallet::balance($this->owner->id));
        $season = (int) DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        $this->assertSame(0, Wallet::spentThisSeason($this->owner->id, $this->league['id'], $season));
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
