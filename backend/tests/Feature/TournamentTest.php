<?php

namespace Tests\Feature;

use App\League\LeagueStarter;
use App\Market\Market;
use App\Models\League;
use App\Models\User;
use App\Support\GameClock;
use App\Tournament\TournamentStage;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 27] National teams from the players' nationalities, tournaments of clubs and nations, and their draw. */
class TournamentTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        // Two countries spread over a club each: Brazil (16 players, two keepers) and Egypt, written once in capitals.
        $this->nationClub('Brazil', 'Brazil', 16, 80);
        $this->nationClub('Egypt', 'EGYPT', 8, 74);
        $this->nationClub('Egypt B', 'Egypt', 8, 72);
        // Too few: no team.
        $this->nationClub('Palestine', 'Palestine', 5, 70);
        $this->artisan('data:nations')->assertSuccessful();
        $this->owner = User::factory()->create(['name' => 'المنظم']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function nationClub(string $club, string $nationality, int $players, int $ovr): int
    {
        $id = DB::table('master_clubs')->insertGetId(['data_version' => '2026', 'name' => "{$club} FC", 'code' => strtoupper(substr($club, 0, 3)), 'league_name' => 'Nation Pool',
            'strength_cp' => $ovr * 100, 'color_primary' => '#000000', 'color_secondary' => '#FFFFFF']);
        for ($i = 0; $i < $players; $i++) {
            DB::table('master_players')->insert(['data_version' => '2026', 'external_id' => $id * 1000 + $i, 'master_club_id' => $id, 'name' => "{$club} {$i}",
                'position' => $i < 2 ? 'GK' : 'CM', 'line' => $i < 2 ? 'gk' : 'mid', 'age' => 25, 'nationality' => $nationality,
                'overall' => $ovr - $i % 5, 'potential' => $ovr, 'value' => 1_000_000, 'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70]);
        }

        return $id;
    }

    private function nation(string $name): int
    {
        return (int) DB::table('master_clubs')->where('source', 'nation')->where('name', $name)->value('id');
    }

    private function clubs(int $n): array
    {
        return DB::table('master_clubs')->where('league_name', 'Test League')->orderByDesc('strength_cp')->limit($n)->pluck('id')->all();
    }

    private function make(array $over = []): array
    {
        return $this->actingAs($this->owner)->postJson('/api/v1/tournaments', $over + [
            'name' => 'كأس الأصدقاء', 'template' => 'custom', 'format' => 'groups', 'group_count' => 2, 'advance_per_group' => 2, 'legs' => 1,
            'teams' => [...$this->clubs(6), $this->nation('Brazil'), $this->nation('Egypt')], 'round_times' => ['21:00'],
            'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString(),
        ])->assertCreated()->json('tournament');
    }

    public function test_the_national_teams_come_from_the_nationalities(): void
    {
        $nations = DB::table('master_clubs')->where('source', 'nation')->orderBy('name')->get();
        // Egypt once (two spellings), Palestine not (five players).
        $this->assertSame(['Brazil', 'Egypt'], $nations->pluck('name')->all());
        $this->assertSame('CAF', $nations[1]->confederation);
        $this->assertSame('EGY', $nations[1]->code);
        // Again: nothing new, and not a league template.
        $this->artisan('data:nations')->assertSuccessful();
        $this->assertSame(2, DB::table('master_clubs')->where('source', 'nation')->count());
        $this->assertNotContains('National Teams', array_column($this->getJson('/api/v1/data/templates')->json('templates'), 'name'));
        $catalog = $this->actingAs($this->owner)->getJson('/api/v1/tournaments/catalog')->assertOk()->json();
        $this->assertSame(['Brazil', 'Egypt'], array_column($catalog['nations'], 'name'));
        $this->assertContains('Palestine', array_column($catalog['missing'], 'name'));
        $this->assertSame(['world_cup', 'club_world_cup', 'afcon', 'euro', 'asian_cup', 'custom'], array_column($catalog['templates'], 'key'));
        $afcon = collect($catalog['templates'])->firstWhere('key', 'afcon');
        $this->assertSame([$this->nation('Egypt')], $afcon['teams']);
    }

    public function test_a_tournament_of_clubs_and_nations_in_groups_then_a_knockout(): void
    {
        $t = $this->make();
        $league = League::findOrFail($t['id']);
        $this->assertSame('tournament', $league->kind);
        $this->assertSame(8, $league->team_count);
        // Egypt's squad from its two clubs: its 12 outfield players and three of its four keepers.
        $egypt = DB::table('clubs')->where('league_id', $league->id)->where('name', 'Egypt')->value('id');
        $this->assertSame(15, DB::table('players')->where('club_id', $egypt)->count());
        // Two groups of four, three rounds, then the semi-finals and the final.
        $this->assertSame([4, 4], DB::table('clubs')->where('league_id', $league->id)->groupBy('group_no')->selectRaw('count(*) as n')->pluck('n')->map(fn ($n) => (int) $n)->all());
        $this->assertSame(12, DB::table('fixtures')->where('season_id', $league->season->id)->where('competition', 'league')->count());
        $sf = DB::table('cup_ties')->where('season_id', $league->season->id)->where('stage', 'sf')->orderBy('slot')->get();
        $this->assertSame(['A1', 'B1'], $sf->pluck('home_from')->all());
        $this->assertSame(['B2', 'A2'], $sf->pluck('away_from')->all());
        // The market is shut, and the knockout is after the groups.
        $this->assertNotNull(Market::closed($league->id));
        $lastGroup = DB::table('fixtures')->where('season_id', $league->season->id)->where('competition', 'league')->max('scheduled_at');
        $firstCup = DB::table('fixtures')->where('season_id', $league->season->id)->where('competition', 'cup')->min('scheduled_at');
        $this->assertTrue($firstCup > $lastGroup);

        // It starts (drawn then), and the groups end: their tables fill the semi-finals.
        $this->assertTrue(LeagueStarter::start($league));
        $season = $league->season->id;
        foreach (DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('is_bye', false)->get() as $f) {
            $strong = DB::table('clubs')->where('id', $f->home_id)->value('strength_snapshot') >= DB::table('clubs')->where('id', $f->away_id)->value('strength_snapshot');
            DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $strong ? 2 : 0, 'away_goals' => $strong ? 0 : 2]);
        }
        TournamentStage::groupsDone($season);
        $tables = TournamentStage::tables($season, $league->id);
        $sf = DB::table('cup_ties')->where('season_id', $season)->where('stage', 'sf')->orderBy('slot')->get();
        $this->assertSame($tables[1][0]['id'], (int) $sf[0]->home_id);
        $this->assertSame($tables[2][1]['id'], (int) $sf[0]->away_id);
        $this->assertSame((int) $sf[0]->home_id, (int) DB::table('fixtures')->where('id', $sf[0]->fixture_id)->value('home_id'));

        // Its page: the groups and the bracket.
        $page = $this->actingAs(User::factory()->create())->getJson("/api/v1/tournaments/{$league->id}")->assertOk()->json('tournament');
        $this->assertSame(['A', 'B'], array_column($page['groups'], 'group'));
        $this->assertSame(['sf', 'final'], array_column($page['bracket'], 'stage'));
    }

    public function test_the_draw_is_for_everyone_drawn_at_the_start_and_the_same_on_every_screen(): void
    {
        $t = $this->make();
        $stranger = User::factory()->create();
        $before = $this->actingAs($stranger)->getJson("/api/v1/tournaments/{$t['id']}/draw")->assertOk()->json();
        $this->assertNull($before['drawn_at']);
        $this->assertSame([], $before['steps']);
        $this->assertFalse($before['can_schedule']);
        // No time set: drawn at the start.
        $this->assertTrue(LeagueStarter::start(League::findOrFail($t['id'])));
        $after = $this->getJson("/api/v1/tournaments/{$t['id']}/draw")->assertOk()->json();
        $this->assertNotNull($after['drawn_at']);
        $this->assertCount(8, $after['steps']);
        $this->assertSame(2, $after['pots'] > 0 ? 2 : 0);
        $this->assertSame(hash('sha256', "legends-draw:{$t['id']}:{$after['seed']}"), $after['commit']);
        // The steps put every team in the group it plays in.
        foreach ($after['steps'] as $s) {
            $this->assertSame(chr(64 + $s['group']), $s['club']['group']);
        }
        $this->assertSame($after['steps'], $this->getJson("/api/v1/tournaments/{$t['id']}/draw")->json('steps'));
    }

    public function test_a_live_draw_at_a_time_set_on_creation(): void
    {
        $t = $this->make(['draw_at' => GameClock::now()->addHours(2)->toIso8601ZuluString()]);
        $draw = $this->getJson("/api/v1/tournaments/{$t['id']}/draw")->json();
        $this->assertSame(64, strlen($draw['commit']));
        $this->assertNull($draw['seed']);
        Carbon::setTestNow(GameClock::now()->addHours(2)->addMinute());
        $this->artisan('leagues:start')->assertSuccessful();
        $this->assertNotNull(League::findOrFail($t['id'])->drawn_at);
    }

    public function test_two_teams_or_three_or_a_knockout(): void
    {
        $two = $this->make(['format' => 'league', 'legs' => 2, 'teams' => $this->clubs(2)]);
        $this->assertSame(2, DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->where('seasons.league_id', $two['id'])->count());
        $ko = $this->make(['format' => 'knockout', 'teams' => $this->clubs(3)]);
        $this->assertSame(['final', 'preliminary'], DB::table('cup_ties')->join('seasons', 'seasons.id', '=', 'cup_ties.season_id')->where('seasons.league_id', $ko['id'])
            ->orderBy('stage')->distinct()->pluck('stage')->all());
        // A shape the count cannot fill, and one team alone.
        $this->actingAs($this->owner)->postJson('/api/v1/tournaments', ['template' => 'custom', 'format' => 'groups', 'group_count' => 4, 'teams' => $this->clubs(6),
            'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()])->assertStatus(422);
        $this->postJson('/api/v1/tournaments', ['template' => 'custom', 'format' => 'league', 'teams' => $this->clubs(1),
            'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()])->assertStatus(422);
    }

    public function test_a_national_team_leaves_a_clubs_players_with_their_club_and_the_owner_coaches_one(): void
    {
        // Every Brazilian is at Brazil FC: none left for the national team, which cannot play.
        $brazilFc = DB::table('master_clubs')->where('name', 'Brazil FC')->value('id');
        $this->actingAs($this->owner)->postJson('/api/v1/tournaments', ['template' => 'custom', 'format' => 'league', 'teams' => [$brazilFc, $this->nation('Brazil')],
            'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()])->assertStatus(422);
        $this->assertSame(0, League::count());
        // With another club, Brazil has its 16, and its maker coaches it.
        $t = $this->make(['format' => 'league', 'teams' => [$this->clubs(1)[0], $this->nation('Brazil')], 'club_id' => $this->nation('Brazil')]);
        $brazil = DB::table('clubs')->where('league_id', $t['id'])->where('name', 'Brazil')->first();
        $this->assertSame(16, DB::table('players')->where('club_id', $brazil->id)->count());
        $this->assertSame($this->owner->id, (int) $brazil->user_id);
        // A coach joins with the code, as in a league.
        $this->assertSame('tournament', $this->getJson("/api/v1/leagues/{$t['id']}")->assertOk()->json('league.kind'));
    }
}
