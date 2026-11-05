<?php

namespace Tests\Feature;

use App\League\LeagueStarter;
use App\Models\League;
use App\Models\User;
use App\Support\GameClock;
use App\Tournament\TournamentFactory;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X68] A tournament's teams to its coaches: shared out by the live draw among those who entered, or named by its organizer. */
class TournamentEntryTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create(['name' => 'المنظم']);
        Wallet::post($this->owner->id, 'daily', 10_000, 'test-grant:'.$this->owner->id);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function make(int $teams, array $over = []): array
    {
        return $this->actingAs($this->owner)->postJson('/api/v1/tournaments', $over + ['template' => 'custom', 'format' => 'league',
            'teams' => DB::table('master_clubs')->where('league_name', 'Test League')->orderByDesc('strength_cp')->limit($teams)->pluck('id')->all(),
            'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString(), 'entry_mode' => 'draw'])->assertCreated()->json('tournament');
    }

    public function test_the_players_enter_and_once_full_the_draw_gives_each_a_team(): void
    {
        $t = $this->make(3);
        $url = "/api/v1/tournaments/{$t['id']}/entry";
        $players = User::factory()->count(4)->create();
        $this->actingAs($players[0])->postJson($url)->assertOk()->assertJsonPath('tournament.entry.is_entrant', true);
        $this->postJson($url)->assertStatus(409);
        // No team by hand before the draw.
        $club = DB::table('clubs')->where('league_id', $t['id'])->value('id');
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$t['id']}/clubs/{$club}/claim")->assertStatus(409);
        // A player leaves and comes back; the organizer enters too.
        $this->actingAs($players[1])->postJson($url)->assertOk();
        $this->deleteJson($url)->assertOk();
        $this->postJson($url)->assertOk();
        $this->assertNull(League::findOrFail($t['id'])->draw_at);
        // The last place: the draw in ten minutes, and every entrant told.
        $this->actingAs($this->owner)->postJson($url)->assertOk();
        $this->actingAs($players[3])->postJson($url)->assertStatus(409);
        $league = League::findOrFail($t['id']);
        $this->assertSame(GameClock::now()->addMinutes(10)->toIso8601ZuluString(), $league->draw_at->toIso8601ZuluString());
        $this->assertSame(3, DB::table('messages')->where('type', 'tournament_full')->count());
        // At its time: each entrant coaches a team, ball by ball, and the steps show it before the league's slots.
        Carbon::setTestNow(GameClock::now()->addMinutes(11));
        $this->artisan('leagues:start')->assertSuccessful();
        $coaches = DB::table('clubs')->where('league_id', $t['id'])->whereNotNull('user_id')->pluck('user_id')->map(fn ($v) => (int) $v)->sort()->values()->all();
        $this->assertSame(collect([$players[0]->id, $players[1]->id, $this->owner->id])->sort()->values()->all(), $coaches);
        $steps = $this->actingAs($players[3])->getJson("/api/v1/tournaments/{$t['id']}/draw")->assertOk()->json('steps');
        $this->assertSame(['owner', 'owner', 'owner', 'slot', 'slot', 'slot'], array_column($steps, 'type'));
        foreach (array_slice($steps, 0, 3) as $s) {
            $this->assertSame($s['user']['id'], (int) DB::table('clubs')->where('id', $s['club']['id'])->value('user_id'));
        }
        $this->actingAs($players[0])->deleteJson($url)->assertStatus(409);
        // The tournament's own group: its coaches, open from its page.
        $this->actingAs($players[0])->getJson("/api/v1/groups/league/{$t['id']}")->assertOk()->assertJsonPath('group.members_count', 3);
    }

    public function test_not_full_at_the_start_whoever_entered_gets_a_team_and_the_rest_play_under_the_computer(): void
    {
        $t = $this->make(4);
        $p = User::factory()->create();
        $this->actingAs($p)->postJson("/api/v1/tournaments/{$t['id']}/entry")->assertOk();
        // An entrant sees the tournament's group before the draw.
        $this->getJson("/api/v1/groups/league/{$t['id']}")->assertOk();
        $this->assertTrue(LeagueStarter::start(League::findOrFail($t['id'])));
        $this->assertSame([$p->id], DB::table('clubs')->where('league_id', $t['id'])->whereNotNull('user_id')->pluck('user_id')->map(fn ($v) => (int) $v)->all());
    }

    public function test_the_organizer_names_each_teams_coach(): void
    {
        $sara = User::factory()->create(['username' => 'sara']);
        $omar = User::factory()->create(['username' => 'omar']);
        $masters = DB::table('master_clubs')->where('league_name', 'Test League')->orderByDesc('strength_cp')->limit(2)->pluck('id')->all();
        $t = $this->make(2, ['entry_mode' => 'assign', 'owners' => [$masters[0] => '@Sara']]);
        $club = fn (int $m) => DB::table('clubs')->where('league_id', $t['id'])->where('master_club_id', $m)->first();
        $this->assertSame($sara->id, (int) $club($masters[0])->user_id);
        $this->assertSame(1, DB::table('messages')->where('user_id', $sara->id)->where('type', 'tournament_team')->count());
        // Later, before the start; only the organizer.
        $this->actingAs($sara)->putJson("/api/v1/tournaments/{$t['id']}/owners", ['owners' => [$club($masters[1])->id => 'omar']])->assertForbidden();
        $this->actingAs($this->owner)->putJson("/api/v1/tournaments/{$t['id']}/owners", ['owners' => [$club($masters[1])->id => 'omar']])->assertOk();
        $this->assertSame($omar->id, (int) $club($masters[1])->user_id);
        // Entering is for a drawn tournament only.
        $this->actingAs(User::factory()->create())->postJson("/api/v1/tournaments/{$t['id']}/entry")->assertStatus(409);
    }

    public function test_up_to_64_teams_and_a_knockout_up_to_32(): void
    {
        $this->template(70, 'Big League');
        $ids = DB::table('master_clubs')->where('league_name', 'Big League')->limit(64)->pluck('id')->all();
        $body = ['template' => 'custom', 'teams' => $ids, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()];
        $this->actingAs($this->owner)->postJson('/api/v1/tournaments', $body + ['format' => 'knockout'])->assertStatus(422);
        $t = $this->postJson('/api/v1/tournaments', $body + ['format' => 'groups', 'group_count' => 8])->assertCreated()->json('tournament');
        $this->assertSame(64, $t['team_count']);
    }

    /** [Sprint 43 A3] 48 in 12 groups with the 8 best thirds; thirds that do not complete a round are refused. */
    public function test_the_world_cup_of_48_shape(): void
    {
        $shape = fn (int $teams, int $groups, int $thirds) => TournamentFactory::assertShape($teams,
            ['format' => 'groups', 'group_count' => $groups, 'advance_per_group' => 2, 'best_thirds' => $thirds]);
        $shape(48, 12, 8);
        $shape(32, 8, 0);
        foreach ([[48, 12, 0], [48, 12, 6], [24, 8, 0 + 8]] as [$teams, $groups, $thirds]) {
            try {
                $shape($teams, $groups, $thirds);
                $this->fail("$teams in $groups groups with $thirds thirds");
            } catch (HttpException $e) {
                $this->assertSame(422, $e->getStatusCode());
            }
        }
        $this->assertSame(12, config('game.tournaments.templates.world_cup_48.groups'));
    }
}
