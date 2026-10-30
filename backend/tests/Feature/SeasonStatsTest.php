<?php

namespace Tests\Feature;

use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X17] The statistics centre adds up to the season's matches, and hides nothing it should not show. */
class SeasonStatsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_stats_add_up_to_the_finished_matches(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'season_end_mode' => 'end',
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $season = (int) DB::table('seasons')->where('league_id', $league['id'])->value('id');
        // Play until three league rounds are done.
        for ($i = 0; $i < 2000 && DB::table('seasons')->where('id', $season)->value('rounds_played') < 3; $i++) {
            Carbon::setTestNow(GameClock::now()->addSeconds(15));
            $this->artisan('matches:prepare');
            MatchRunner::step();
        }

        $s = $this->getJson("/api/v1/leagues/{$league['id']}/stats")->assertOk()->json();
        $league_fixtures = DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('status', 'finished')->where('is_bye', false)->get();
        $this->assertGreaterThanOrEqual(6, $league_fixtures->count());
        $goals = $league_fixtures->sum('home_goals') + $league_fixtures->sum('away_goals');

        // The table.
        $this->assertCount(4, $s['table']);
        $this->assertSame($goals, array_sum(array_column($s['table'], 'goals_for')));
        $this->assertSame(2 * $league_fixtures->count(), array_sum(array_column($s['table'], 'played')));
        foreach ($s['table'] as $r) {
            $this->assertSame($r['played'] ? intdiv(100 * $r['goals_for'], $r['played']) : 0, $r['goals_per_match_x100']);
        }
        // The scorers never count more goals than were scored (every competition), and are sorted.
        $all = DB::table('fixtures')->where('season_id', $season)->where('status', 'finished')->get();
        $this->assertLessThanOrEqual($all->sum('home_goals') + $all->sum('away_goals'), array_sum(array_column($s['scorers'], 'goals')));
        $g = array_column($s['scorers'], 'goals');
        $this->assertSame($g, collect($g)->sortDesc()->values()->all());
        // The squads' value is every club player's value.
        $this->assertSame((int) DB::table('players')->where('league_id', $league['id'])->whereNotNull('club_id')->sum('value'), array_sum(array_column($s['value'], 'value')));
        // Every club has its runs, never longer than its matches.
        $this->assertCount(4, $s['streaks']);
        foreach ($s['streaks'] as $r) {
            $this->assertLessThanOrEqual(DB::table('fixtures')->where('season_id', $season)->where('status', 'finished')->where(fn ($q) => $q->where('home_id', $r['club']['id'])->orWhere('away_id', $r['club']['id']))->count(), max($r['best']));
            $this->assertLessThanOrEqual(5, count($r['form']));
        }
        $this->assertCount(4, $s['finance']);
        // [X61 E12] Home and away add up to the table.
        foreach ($s['split'] as $r) {
            $row = collect($s['table'])->firstWhere('club.id', $r['club']['id']);
            $this->assertSame($row['played'], $r['home']['played'] + $r['away']['played']);
            $this->assertSame($row['goals_for'], $r['home']['goals_for'] + $r['away']['goals_for']);
        }
        // [X61 E5] The awards: the best player played enough, the young one is young, the run is a club's best.
        $a = $this->getJson("/api/v1/leagues/{$league['id']}/awards")->assertOk()->json();
        $this->assertNotNull($a['mvp']);
        $this->assertGreaterThanOrEqual(3, $a['mvp']['matches']);
        $this->assertGreaterThanOrEqual(30, $a['mvp']['average_x10']);
        if ($a['young']) {
            $this->assertLessThanOrEqual(21, $a['young']['player']['age']);
        }
        $this->assertSame((int) $league_fixtures->max('round'), $a['of_the_round']['round']);
        if ($a['scorer']) {
            $this->assertSame($s['scorers'][0]['goals'] >= $a['scorer']['goals'], true);
        }
        $this->actingAs(User::factory()->create())->getJson("/api/v1/leagues/{$league['id']}/awards")->assertForbidden();
        $this->actingAs($owner);
        // No tactic in it.
        $text = json_encode($s);
        foreach (['pressing', 'tempo', 'style', 'positioning', 'marking'] as $hidden) {
            $this->assertStringNotContainsString("\"{$hidden}\"", $text);
        }
        // Members only (a stranger does not even see the league).
        $this->actingAs(User::factory()->create())->getJson("/api/v1/leagues/{$league['id']}/stats")->assertNotFound();
    }
}
