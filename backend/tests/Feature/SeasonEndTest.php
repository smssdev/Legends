<?php

namespace Tests\Feature;

use App\Economy\Contracts;
use App\League\ClubLedger;
use App\League\MatchRunner;
use App\Models\User;
use App\Season\Objectives;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The end of a season and the next one [PLAN 2.11, 2.20, Sprint 33]. */
class SeasonEndTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function devLeague(string $end = 'renew'): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'season_end_mode' => $end,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
    }

    /** The server's minute-by-minute work, with nobody touching anything, until the season is over. */
    private function playSeason(int $number): void
    {
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->where('number', $number)->value('id');
        for ($i = 0; $i < 3000 && DB::table('seasons')->where('id', $season)->value('status') === 'running'; $i++) {
            Carbon::setTestNow(GameClock::now()->addSeconds(15));
            $this->artisan('matches:prepare');
            MatchRunner::step();
            $this->artisan('seasons:close');
        }
    }

    public function test_the_objectives_follow_the_strength(): void
    {
        $this->assertSame(['target' => 1, 'kind' => 'title'], Objectives::league(1, 10));
        $this->assertSame(['target' => 3, 'kind' => 'top'], Objectives::league(2, 10));
        $this->assertSame(['target' => 6, 'kind' => 'mid'], Objectives::league(4, 10));
        $this->assertSame(['target' => 8, 'kind' => 'survive'], Objectives::league(9, 10));
        $this->assertSame('final', Objectives::cup(1, 16));
        $this->assertSame('sf', Objectives::cup(5, 16));
        $this->assertSame('qf', Objectives::cup(12, 16));
        $this->assertSame('sf', Objectives::cup(4, 4));
    }

    public function test_a_whole_season_ends_and_the_next_starts_from_scratch_with_nobody_doing_anything(): void
    {
        $this->devLeague();
        $mine = $this->league['my_club_id'];
        // The coach sees his objectives when he picks the team.
        $club = collect($this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/clubs")->json('clubs'))->firstWhere('id', $mine);
        $this->assertNotNull($club['objectives']['league']['target']);
        // Things the new season must undo.
        $p = DB::table('players')->where('club_id', $mine)->orderBy('id')->first();
        DB::table('players')->where('id', $p->id)->update(['training_bonus' => 3]);
        DB::table('stadium_sections')->insert(['club_id' => $mine, 'section' => 'seats', 'stage' => 2, 'parts' => 1]);
        // [X62 E1] Two players from another club: one renewed into next season (he stays, with his training), one not.
        $other = (int) DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $mine)->value('id');
        [$kept, $back] = DB::table('players')->where('club_id', $other)->orderBy('id')->limit(2)->pluck('id')->all();
        DB::table('players')->whereIn('id', [$kept, $back])->update(['club_id' => $mine, 'training_bonus' => 2]);
        $fee = Contracts::renewal((int) DB::table('players')->where('id', $kept)->value('value'), (int) DB::table('seasons')->where('league_id', $this->league['id'])->value('rounds'), 1);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/team/contracts/{$kept}/renew", ['seasons' => 9])->assertStatus(422);
        $c = $this->postJson("/api/v1/leagues/{$this->league['id']}/team/contracts/{$kept}/renew", ['seasons' => 1])->assertOk()->json();
        $this->assertSame(2, collect($c['players'])->firstWhere('id', $kept)['until']);
        $this->assertSame(-$fee, (int) DB::table('club_transactions')->where('club_id', $mine)->where('type', 'contract_renewal')->value('amount'));

        $this->playSeason(1);
        $this->assertSame($mine, (int) DB::table('players')->where('id', $kept)->value('club_id'));
        $this->assertSame(2, (int) DB::table('players')->where('id', $kept)->value('training_bonus'));
        $this->assertSame($other, (int) DB::table('players')->where('id', $back)->value('club_id'));

        $old = DB::table('seasons')->where('league_id', $this->league['id'])->where('number', 1)->first();
        $this->assertSame('finished', $old->status);
        // Titles: the league's three and the cup's two; every objective judged, with the coach.
        $this->assertSame(3, DB::table('titles')->where('season_id', $old->id)->where('competition', 'league')->count());
        $this->assertSame(2, DB::table('titles')->where('season_id', $old->id)->where('competition', 'cup')->count());
        $this->assertSame(0, DB::table('club_objectives')->where('season_id', $old->id)->whereNull('achieved')->count());
        $this->assertSame($this->owner->id, DB::table('club_objectives')->where('season_id', $old->id)->where('club_id', $mine)->value('user_id'));
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'season_end')->count());

        // The new season: running, from scratch, the coach still with his club.
        $new = DB::table('seasons')->where('league_id', $this->league['id'])->where('number', 2)->first();
        $this->assertSame('running', $new->status);
        $this->assertSame((int) $old->rounds, (int) $new->rounds);
        $this->assertGreaterThan(0, DB::table('fixtures')->where('season_id', $new->id)->count());
        $this->assertSame(8, DB::table('club_objectives')->where('season_id', $new->id)->count());
        $this->assertSame(0, (int) DB::table('players')->where('id', $p->id)->value('training_bonus'));
        $this->assertSame($mine, (int) DB::table('players')->where('id', $p->id)->value('club_id'));
        $this->assertSame(0, DB::table('stadium_sections')->where('club_id', $mine)->count());
        $this->assertSame(3_000_000, (int) DB::table('clubs')->where('id', $mine)->value('balance'));
        $this->assertSame(3_000_000, ClubLedger::sum($mine));
        $this->assertSame($mine, (int) DB::table('league_memberships')->where('season_id', $new->id)->where('user_id', $this->owner->id)->value('club_id'));
        $this->assertSame($mine, DB::table('clubs')->where('id', $mine)->value('user_id') ? $mine : null);

        // The hall of fame and the coach's profile keep it.
        $honours = $this->getJson("/api/v1/leagues/{$this->league['id']}/honours")->assertOk()->json('seasons');
        $this->assertSame([2, 1], array_column($honours, 'number'));
        $this->assertCount(5, $honours[1]['titles']);
        $profile = $this->getJson("/api/v1/coaches/{$this->owner->id}")->assertOk()->json();
        $this->assertSame(2, $profile['objectives']['total']);
        $this->assertGreaterThan(0, $profile['record']['played']);

        // And the second season plays on by itself too.
        $this->playSeason(2);
        $this->assertSame('finished', DB::table('seasons')->where('id', $new->id)->value('status'));
        $this->assertSame(3, DB::table('seasons')->where('league_id', $this->league['id'])->count());
    }

    public function test_a_league_set_to_end_ends(): void
    {
        $this->devLeague('end');
        $this->playSeason(1);
        $this->assertSame('finished', DB::table('leagues')->where('id', $this->league['id'])->value('status'));
        $this->assertSame(1, DB::table('seasons')->where('league_id', $this->league['id'])->count());
    }
}
