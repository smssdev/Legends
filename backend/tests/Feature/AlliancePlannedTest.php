<?php

namespace Tests\Feature;

use App\League\Alliance;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 40 D1, D2] The alliance tournament planned as the league is made, and two team-mates who meet. */
class AlliancePlannedTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function admin(): User
    {
        return User::factory()->create(['role' => 'admin']);
    }

    /** A coach takes a free club of the league (approved by its owner first). */
    private function join(User $owner, array $league, User $coach): int
    {
        $id = $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertCreated()->json('request.id');
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/requests/{$id}/approve")->assertOk();
        $club = (int) DB::table('clubs')->where('league_id', $league['id'])->whereNull('user_id')->orderBy('id')->value('id');
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated();

        return $club;
    }

    public function test_the_maker_splits_the_coaches_and_the_teams_are_formed_before_the_first_round(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create(['username' => 'boss']);
        $ali = User::factory()->create(['username' => 'ali']);
        $omar = User::factory()->create(['username' => 'omar']);
        $sara = User::factory()->create(['username' => 'sara']);
        $first = GameClock::now()->addDays(3)->toIso8601ZuluString();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'alliance' => ['size' => 2, 'assign' => 'pick', 'a' => ['boss', 'ali'], 'b' => ['omar', 'sara'], 'first_round_at' => $first]]);
        $t = DB::table('alliance_tournaments')->where('league_id', $league['id'])->first();
        $this->assertSame('pending', $t->status);
        $this->assertNull($t->formed_at);
        $mine = (int) $league['my_club_id'];
        $clubs = ['ali' => $this->join($owner, $league, $ali), 'omar' => $this->join($owner, $league, $omar), 'sara' => $this->join($owner, $league, $sara)];
        Alliance::review($t->id, $this->admin(), true);
        $this->assertSame(0, DB::table('alliance_members')->where('tournament_id', $t->id)->count());
        $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}/alliance")->assertOk()
            ->assertJsonPath('tournament.formed', false)->assertJsonPath('tournament.plan.b', ['omar', 'sara']);
        // Half an hour before its first round: the maker's split, and the first round between the two alliances.
        Carbon::setTestNow(Carbon::parse($first)->subMinutes(30));
        Alliance::tick();
        $members = DB::table('alliance_members')->where('tournament_id', $t->id)->pluck('alliance', 'club_id')->map(fn ($v) => $v)->all();
        $this->assertSame(['a', 'a', 'b', 'b'], [$members[$mine], $members[$clubs['ali']], $members[$clubs['omar']], $members[$clubs['sara']]]);
        $this->getJson("/api/v1/leagues/{$league['id']}/alliance")->assertJsonPath('tournament.formed', true);
        foreach (DB::table('alliance_ties')->where('tournament_id', $t->id)->get() as $tie) {
            $this->assertSame('match', $tie->kind);
            $this->assertNotSame($members[$tie->home_id], $members[$tie->away_id]);
        }
    }

    public function test_by_the_draw_with_the_computer_s_clubs_for_places_nobody_holds_and_sizes_from_one_to_five(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 6, 'alliance' => ['size' => 3]]);
        $t = DB::table('alliance_tournaments')->where('league_id', $league['id'])->first();
        Alliance::review($t->id, $this->admin(), true);
        Carbon::setTestNow(Carbon::parse($t->first_round_at, 'UTC'));
        Alliance::tick();
        $this->assertSame(3, DB::table('alliance_members')->where('tournament_id', $t->id)->where('alliance', 'a')->count());
        $this->assertSame(3, DB::table('alliance_members')->where('tournament_id', $t->id)->where('alliance', 'b')->count());
        // Six alliances' places in a league of four: refused; and 6 a side is over the limit.
        $other = User::factory()->create();
        $this->makeLeagueRefused($other, ['team_count' => 4, 'alliance' => ['size' => 3]]);
        $this->makeLeagueRefused($other, ['team_count' => 12, 'alliance' => ['size' => 6]]);
    }

    private function makeLeagueRefused(User $owner, array $over): void
    {
        Wallet::post($owner->id, 'daily', 1000, 'grant:'.uniqid());
        $this->actingAs($owner)->postJson('/api/v1/leagues', $this->settings($over))->assertStatus(422);
    }

    public function test_two_team_mates_agree_who_goes_on_and_he_swaps_up_to_three_players(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create(['username' => 'boss']);
        $ali = User::factory()->create(['username' => 'ali']);
        $league = $this->makeLeague($owner, ['team_count' => 4, 'alliance' => ['size' => 2, 'assign' => 'pick', 'a' => ['boss', 'ali']]]);
        $t = DB::table('alliance_tournaments')->where('league_id', $league['id'])->first();
        $mine = (int) $league['my_club_id'];
        $his = $this->join($owner, $league, $ali);
        Alliance::review($t->id, $this->admin(), true);
        DB::table('alliance_tournaments')->where('id', $t->id)->update(['status' => 'running', 'formed_at' => GameClock::now()]);
        $bots = DB::table('clubs')->where('league_id', $league['id'])->whereNull('user_id')->orderBy('id')->pluck('id')->all();
        foreach ([$mine => 'a', $his => 'a', $bots[0] => 'b', $bots[1] => 'b'] as $club => $side) {
            DB::table('alliance_members')->insert(['tournament_id' => $t->id, 'club_id' => $club, 'alliance' => $side]);
        }
        // A tie of the two of alliance a (as when only they are left on that side of a round).
        $tie = DB::table('alliance_ties')->insertGetId(['tournament_id' => $t->id, 'round' => 2, 'kind' => 'captain', 'home_id' => $mine, 'away_id' => $his,
            'scheduled_at' => GameClock::now()->addDay(), 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $url = "/api/v1/leagues/{$league['id']}/alliance/ties/{$tie}";
        // Each picks; different picks decide nothing, the same pick decides it.
        $this->actingAs($owner)->postJson("{$url}/decide", ['winner' => $mine])->assertOk();
        $this->actingAs($ali)->postJson("{$url}/decide", ['winner' => $his])->assertOk();
        $this->assertNull(DB::table('alliance_ties')->where('id', $tie)->value('winner_id'));
        $this->actingAs($ali)->postJson("{$url}/decide", ['winner' => $mine])->assertOk();
        $this->assertSame($mine, (int) DB::table('alliance_ties')->where('id', $tie)->value('winner_id'));
        // The one who went on swaps two, then one more; a fourth is over the limit; the other coach cannot.
        $give = DB::table('players')->where('club_id', $mine)->orderBy('id')->limit(3)->pluck('id')->all();
        $take = DB::table('players')->where('club_id', $his)->orderBy('id')->limit(3)->pluck('id')->all();
        $this->actingAs($ali)->postJson("{$url}/swap", ['give' => [$take[0]], 'take' => [$give[0]]])->assertForbidden();
        $this->actingAs($owner)->postJson("{$url}/swap", ['give' => [$give[0], $give[1]], 'take' => [$take[0], $take[1]]])->assertOk()->assertJsonPath('tournament.ties.0.swaps', 2);
        $this->assertSame($mine, (int) DB::table('players')->where('id', $take[0])->value('club_id'));
        $this->assertSame($his, (int) DB::table('players')->where('id', $give[0])->value('club_id'));
        $this->postJson("{$url}/swap", ['give' => [$give[2], DB::table('players')->where('club_id', $mine)->whereNotIn('id', [$give[2], $take[0], $take[1]])->value('id')], 'take' => [$take[2], DB::table('players')->where('club_id', $his)->whereNotIn('id', [$take[2], $give[0], $give[1]])->value('id')]])->assertStatus(422);
        $this->postJson("{$url}/swap", ['give' => [$give[2]], 'take' => [$take[2]]])->assertOk();
    }
}
