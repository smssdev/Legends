<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 20 B4] Friendlies: a real match now, three a day, with no effect but a little training. */
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
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => '2026-10-24T10:00:00Z']);
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

    public function test_three_a_day_with_no_effect_but_training(): void
    {
        $view = $this->actingAs($this->owner)->getJson($this->url())->assertOk()->assertJsonPath('left', 3)->assertJsonPath('blocked', null)->json();
        $this->assertCount(3, $view['opponents']);
        $this->assertCount(1, array_filter($view['opponents'], fn ($o) => $o['recommended']));
        $opponent = $view['opponents'][0]['id'];
        $before = DB::table('players')->where('club_id', $this->mine)->get(['id', 'fitness', 'injured_matches', 'suspended_matches', 'training_progress', 'overall'])->keyBy('id');
        $balance = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $fixtures = DB::table('fixtures')->where('status', 'finished')->count();

        $played = $this->postJson($this->url(), ['opponent_id' => $opponent])->assertCreated()->assertJsonPath('left', 2)->json('friendly');
        $this->assertSame($opponent, $played['opponent']['id']);
        $this->assertCount($played['goals_for'] + $played['goals_against'], $played['report']['goals']);
        $this->assertGreaterThanOrEqual(11, $played['report']['played']);

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

        $this->postJson($this->url(), ['opponent_id' => $opponent])->assertCreated();
        $this->postJson($this->url(), ['opponent_id' => $opponent])->assertCreated()->assertJsonPath('left', 0);
        $this->postJson($this->url(), ['opponent_id' => $opponent])->assertStatus(429);
        // A new day in Cairo: three again.
        Carbon::setTestNow('2026-10-22 22:30:00');
        $this->getJson($this->url())->assertJsonPath('left', 3)->assertJsonCount(3, 'recent');
    }

    public function test_not_before_the_match_nor_against_a_club_of_another_league(): void
    {
        $this->actingAs($this->owner)->postJson($this->url(), ['opponent_id' => $this->mine])->assertNotFound();
        $other = $this->makeLeague(User::factory()->create(), ['team_count' => 4, 'starts_at' => '2026-10-24T10:00:00Z']);
        $this->actingAs($this->owner)->postJson($this->url(), ['opponent_id' => $other['my_club_id']])->assertNotFound();
        // The club's match in 30 minutes: no friendly.
        $opponent = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->value('id');
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        DB::table('fixtures')->insert(['season_id' => $season, 'competition' => 'league', 'round' => 99, 'home_id' => $this->mine, 'away_id' => $opponent,
            'scheduled_at' => GameClock::now()->addMinutes(30), 'status' => 'scheduled', 'is_bye' => false, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $this->getJson($this->url())->assertJsonPath('blocked.reason', 'before_match');
        $this->postJson($this->url(), ['opponent_id' => $opponent])->assertConflict();
        $this->actingAs(User::factory()->create())->getJson($this->url())->assertForbidden();
    }
}
