<?php

namespace Tests\Feature;

use App\League\Alliance;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X27] The alliance tournament: approval, the draw that keeps team-mates apart, the captains' picks, the champion. */
class AllianceTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private string $url;

    /** @var list<User> */
    private array $coaches = [];

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(clubs: 20, full: true);
        $this->owner = User::factory()->create(['username' => 'boss']);
        $this->league = $this->makeLeague($this->owner, ['team_count' => 10, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->url = "/api/v1/leagues/{$this->league['id']}/alliance";
        // Nine more coaches, each with a club of the league.
        $this->coaches = [$this->owner];
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        foreach (DB::table('clubs')->where('league_id', $this->league['id'])->whereNull('user_id')->orderBy('id')->limit(9)->pluck('id') as $i => $club) {
            $u = User::factory()->create(['username' => 'coach'.($i + 1)]);
            DB::table('clubs')->where('id', $club)->update(['user_id' => $u->id]);
            DB::table('league_memberships')->insert(['league_id' => $this->league['id'], 'season_id' => $season, 'user_id' => $u->id, 'club_id' => $club,
                'joined_at' => GameClock::now(), 'last_active_at' => GameClock::now(), 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
            $this->coaches[] = $u;
        }
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function create(int $size = 5): int
    {
        $this->actingAs($this->owner)->postJson($this->url, ['name' => 'كأس التحالفات', 'captain_a' => 'boss', 'captain_b' => 'Coach1', 'size' => $size,
            'first_round_at' => GameClock::now()->addHours(3)->toIso8601ZuluString()])->assertCreated();

        return (int) DB::table('alliance_tournaments')->value('id');
    }

    public function test_the_draw_never_pairs_team_mates_while_the_other_alliance_has_coaches(): void
    {
        foreach (range(1, 300) as $seed) {
            $na = 1 + $seed % 7;
            $nb = 1 + intdiv($seed, 7) % 7;
            $entrants = [];
            foreach (range(1, $na) as $i) {
                $entrants[$i] = 'a';
            }
            foreach (range(1, $nb) as $i) {
                $entrants[100 + $i] = 'b';
            }
            $ties = Alliance::pair($entrants, $seed);
            $seen = [];
            foreach ($ties as $t) {
                $seen = [...$seen, $t['home'], ...($t['away'] ? [$t['away']] : [])];
                if ($t['kind'] === 'match') {
                    $this->assertNotSame($entrants[$t['home']], $entrants[$t['away']]);
                }
                if (in_array($t['kind'], ['captain', 'walkover'], true)) {
                    $this->assertSame($entrants[$t['home']], $entrants[$t['away']]);
                }
            }
            sort($seen);
            $all = array_keys($entrants);
            sort($all);
            $this->assertSame($all, $seen, "seed {$seed}: everyone drawn once");
            $this->assertSame(min($na, $nb), count(array_filter($ties, fn ($t) => $t['kind'] === 'match')));
        }
        // A final of team-mates is not played.
        $this->assertSame('walkover', Alliance::pair([1 => 'a', 2 => 'a'], 1)[0]['kind']);
        $this->assertSame('match', Alliance::pair([1 => 'a', 2 => 'b'], 1)[0]['kind']);
    }

    public function test_the_owner_asks_and_it_waits_for_the_developers(): void
    {
        $this->actingAs($this->owner);
        $at = GameClock::now()->addHours(3)->toIso8601ZuluString();
        $this->postJson($this->url, ['name' => 'كأس', 'captain_a' => 'boss', 'captain_b' => 'boss', 'size' => 5, 'first_round_at' => $at])->assertStatus(422);
        $this->postJson($this->url, ['name' => 'كأس', 'captain_a' => 'boss', 'captain_b' => 'coach1', 'size' => 6, 'first_round_at' => $at])->assertStatus(422);
        $this->postJson($this->url, ['name' => 'كأس', 'captain_a' => 'boss', 'captain_b' => 'coach1', 'size' => 5, 'first_round_at' => GameClock::now()->addMinutes(5)->toIso8601ZuluString()])->assertStatus(422);
        $this->actingAs($this->coaches[3])->postJson($this->url, ['name' => 'كأس', 'captain_a' => 'boss', 'captain_b' => 'coach1', 'size' => 5, 'first_round_at' => $at])->assertStatus(403);

        $id = $this->create();
        $view = $this->actingAs($this->coaches[2])->getJson($this->url)->assertOk()->json('tournament');
        $this->assertSame('pending', $view['status']);
        $this->assertCount(5, $view['alliances']['a']['clubs']);
        $this->assertCount(5, $view['alliances']['b']['clubs']);
        // The captains each in his own alliance.
        $this->assertContains($this->league['my_club_id'], array_column($view['alliances']['a']['clubs'], 'id'));
        $this->assertSame([], $view['ties']);
        // One at a time.
        $this->actingAs($this->owner)->postJson($this->url, ['name' => 'أخرى', 'captain_a' => 'boss', 'captain_b' => 'coach1', 'size' => 5, 'first_round_at' => $at])->assertStatus(409);

        // The developers: the panel is theirs only.
        $this->actingAs($this->coaches[2])->getJson('/api/v1/admin/alliances')->assertStatus(403);
        $admin = User::factory()->create(['role' => 'admin']);
        Alliance::review($id, $admin, false, 'اختر موعداً آخر');
        $this->assertSame('rejected', $this->getJson($this->url)->json('tournament.status'));
        $this->assertTrue($this->actingAs($this->owner)->getJson($this->url)->json('can_create'));
    }

    public function test_approved_it_plays_round_by_round_to_a_champion_alliance(): void
    {
        $id = $this->create(5);
        Alliance::review($id, User::factory()->create(['role' => 'admin']), true);
        $first = DB::table('alliance_ties')->where('tournament_id', $id)->where('round', 1)->get();
        // Five against five: five matches, no team-mates.
        $this->assertSame(5, $first->where('kind', 'match')->count());
        $this->assertSame(5, DB::table('fixtures')->where('competition', 'alliance')->count());

        $alliance = DB::table('alliance_members')->where('tournament_id', $id)->pluck('alliance', 'club_id');
        // Alliance A wins every match it plays.
        for ($guard = 0; $guard < 10 && DB::table('alliance_tournaments')->where('id', $id)->value('status') === 'running'; $guard++) {
            $round = DB::table('alliance_ties')->where('tournament_id', $id)->max('round');
            foreach (DB::table('alliance_ties')->where('tournament_id', $id)->where('round', $round)->whereNull('winner_id')->get() as $tie) {
                if ($tie->kind === 'match') {
                    $f = DB::table('fixtures')->where('id', $tie->fixture_id)->first();
                    $homeWins = $alliance[$f->home_id] === 'a';
                    Alliance::fixtureDone($f, ['score' => ['home' => $homeWins ? 2 : 0, 'away' => $homeWins ? 0 : 2], 'shootout' => null]);
                } elseif ($tie->kind === 'captain') {
                    $captain = $alliance[$tie->home_id] === 'a' ? $this->owner : $this->coaches[1];
                    $this->actingAs($this->coaches[5])->postJson("{$this->url}/ties/{$tie->id}/decide", ['winner' => $tie->home_id])->assertStatus(403);
                    $this->actingAs($captain)->postJson("{$this->url}/ties/{$tie->id}/decide", ['winner' => $tie->home_id])->assertOk();
                }
            }
        }
        $t = DB::table('alliance_tournaments')->where('id', $id)->first();
        $this->assertSame('finished', $t->status);
        $this->assertSame('a', $t->winner);
        // A's five went on after round 1; only A left: the title is A's without another match against itself.
        $this->assertSame(1, (int) DB::table('alliance_ties')->where('tournament_id', $id)->max('round'));
    }

    public function test_a_captain_who_does_not_pick_in_time_leaves_it_to_the_stronger_club(): void
    {
        $id = $this->create(3);
        Alliance::review($id, User::factory()->create(['role' => 'admin']), true);
        $alliance = DB::table('alliance_members')->where('tournament_id', $id)->pluck('alliance', 'club_id');
        // Round 1: three matches; A wins two, B one: then two A team-mates and one B (a bye for an A, or...).
        $i = 0;
        foreach (DB::table('alliance_ties')->where('tournament_id', $id)->where('round', 1)->get() as $tie) {
            $f = DB::table('fixtures')->where('id', $tie->fixture_id)->first();
            $winA = $i++ < 2;
            $homeWins = ($alliance[$f->home_id] === 'a') === $winA;
            Alliance::fixtureDone($f, ['score' => ['home' => $homeWins ? 1 : 0, 'away' => $homeWins ? 0 : 1], 'shootout' => null]);
        }
        $second = DB::table('alliance_ties')->where('tournament_id', $id)->where('round', 2)->get();
        // Three left (two of A, one of B): A against B, and the other A has a bye. No team-mates meet.
        $this->assertSame(1, $second->where('kind', 'match')->count());
        $this->assertSame(1, $second->where('kind', 'bye')->count());
        // The round's time comes in the league's gap after the first.
        $this->assertTrue(Carbon::parse($second->first()->scheduled_at)->gt(Carbon::parse(DB::table('alliance_ties')->where('round', 1)->value('scheduled_at'))));

        // A captain's tie, made by hand: not picked by its time, the stronger club goes on.
        $a = $alliance->filter(fn ($x) => $x === 'a')->keys()->take(2)->all();
        DB::table('alliance_ties')->insert(['tournament_id' => $id, 'round' => 9, 'kind' => 'captain', 'home_id' => $a[0], 'away_id' => $a[1],
            'scheduled_at' => GameClock::now()->addMinute(), 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $this->assertSame(0, Alliance::tick());
        Carbon::setTestNow(GameClock::now()->addMinutes(2));
        $this->assertSame(1, Alliance::tick());
        $stronger = DB::table('clubs')->whereIn('id', $a)->orderByDesc('strength_snapshot')->orderBy('id')->value('id');
        $this->assertSame($stronger, DB::table('alliance_ties')->where('round', 9)->value('winner_id'));

        // In time: the captain of that alliance picks (not another coach, and only one of the two).
        $tie = DB::table('alliance_ties')->insertGetId(['tournament_id' => $id, 'round' => 10, 'kind' => 'captain', 'home_id' => $a[0], 'away_id' => $a[1],
            'scheduled_at' => GameClock::now()->addHour(), 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $this->actingAs($this->coaches[1])->postJson("{$this->url}/ties/{$tie}/decide", ['winner' => $a[1]])->assertStatus(403);
        $this->actingAs($this->owner)->postJson("{$this->url}/ties/{$tie}/decide", ['winner' => 999999])->assertStatus(422);
        $this->actingAs($this->owner)->postJson("{$this->url}/ties/{$tie}/decide", ['winner' => $a[1]])->assertOk();
        $this->assertSame($a[1], (int) DB::table('alliance_ties')->where('id', $tie)->value('winner_id'));
        $this->actingAs($this->owner)->postJson("{$this->url}/ties/{$tie}/decide", ['winner' => $a[0]])->assertStatus(409);
    }
}
