<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X95] game:reset: the game from zero, the admins and the game's data kept. */
class GameResetTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private function game(): array
    {
        $this->template(full: true);
        $admin = User::factory()->create(['role' => 'admin', 'google_id' => 'g-admin']);
        $coach = User::factory()->create();
        $league = $this->makeLeague($coach, ['team_count' => 4]);

        return [$admin, $coach, $league];
    }

    public function test_without_force_it_only_says_what_would_go(): void
    {
        [$admin, $coach] = $this->game();
        $this->artisan('game:reset')->expectsOutputToContain('لم يُحذف شيء')->assertSuccessful();
        $this->assertTrue(User::whereKey($coach->id)->exists());
        $this->assertGreaterThan(0, DB::table('leagues')->count());
    }

    public function test_the_game_starts_from_zero_with_the_admins_and_the_data(): void
    {
        [$admin, $coach] = $this->game();
        $clubs = DB::table('master_clubs')->count();
        $players = DB::table('master_players')->count();
        $this->artisan('game:reset --force')->assertSuccessful();

        foreach (['leagues', 'clubs', 'players', 'fixtures', 'matches', 'seasons', 'league_memberships', 'wallets', 'wallet_transactions', 'club_transactions', 'messages', 'sessions'] as $t) {
            $this->assertSame(0, DB::table($t)->count(), $t);
        }
        $this->assertFalse(User::whereKey($coach->id)->exists());
        // The admin signs in again as before (his Google link kept), and the game's data is whole.
        $this->assertSame('g-admin', User::find($admin->id)->google_id);
        $this->assertSame($clubs, DB::table('master_clubs')->count());
        $this->assertSame($players, DB::table('master_players')->count());
        $this->assertGreaterThan(0, DB::table('migrations')->count());
        // And a new game works: a league made after it.
        $this->makeLeague(User::factory()->create(), ['team_count' => 4]);
        $this->assertSame(1, DB::table('leagues')->count());
    }

    public function test_it_waits_for_a_live_match(): void
    {
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $f = DB::table('fixtures')->whereNotNull('home_id')->whereNotNull('away_id')->first();
        $now = GameClock::now();
        DB::table('matches')->insert(['fixture_id' => $f->id, 'seed' => 1, 'engine_version' => 1, 'config_snapshot' => '{}', 'initial_state' => '{}', 'state' => '{}',
            'home_goals' => 0, 'away_goals' => 0, 'mode' => 'league', 'status' => 'live', 'started_at' => $now, 'created_at' => $now, 'updated_at' => $now]);
        $this->artisan('game:reset --force')->assertFailed();
        $this->assertSame(1, DB::table('leagues')->count());
    }
}
