<?php

namespace Tests\Feature;

use App\League\LiveDraw;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 40 C1] A league made with the draw: its maker chooses the teams and the players, the draw gives each his team. */
class LeagueDrawEntryTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_maker_names_the_teams_and_players_and_the_draw_gives_each_his_team(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $masters = $this->template(full: true);
        $owner = User::factory()->create(['username' => 'boss']);
        $a = User::factory()->create(['username' => 'ali']);
        $b = User::factory()->create(['username' => 'omar']);
        // Four chosen teams (not the four strongest), three players: the fourth team to the computer.
        $chosen = [$masters[1], $masters[3], $masters[5], $masters[7]];
        $league = $this->makeLeague($owner, ['team_count' => 4, 'entry_mode' => 'draw', 'club_id' => null, 'club_ids' => $chosen,
            'draw_users' => ['@Ali', 'omar'], 'draw_at' => GameClock::now()->addHour()->toIso8601ZuluString()]);
        $id = $league['id'];
        $this->assertEqualsCanonicalizing($chosen, DB::table('clubs')->where('league_id', $id)->pluck('master_club_id')->map(fn ($v) => (int) $v)->all());
        // Nobody holds a team before the draw, and nobody takes one by hand.
        $this->assertSame(0, DB::table('clubs')->where('league_id', $id)->whereNotNull('user_id')->count());
        $club = DB::table('clubs')->where('league_id', $id)->value('id');
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$id}/clubs/{$club}/claim")->assertStatus(409);
        // The players are told, and in the league's group already.
        $this->assertSame(1, DB::table('messages')->where('user_id', $a->id)->where('type', 'draw_entry')->count());
        $group = DB::table('chat_groups')->where('league_id', $id)->value('id');
        $this->assertSame(3, DB::table('chat_group_members')->where('chat_group_id', $group)->count());
        $this->getJson("/api/v1/leagues/{$id}/draw")->assertOk()->assertJsonPath('entry_mode', 'draw')->assertJsonCount(3, 'entrants')->assertJsonCount(0, 'owners');

        // At its time: three players, three teams, each once; the fourth stays the computer's.
        Carbon::setTestNow(GameClock::now()->addHour()->addMinute());
        LiveDraw::due();
        $held = DB::table('clubs')->where('league_id', $id)->whereNotNull('user_id')->pluck('user_id')->map(fn ($v) => (int) $v)->all();
        $this->assertEqualsCanonicalizing([$owner->id, $a->id, $b->id], $held);
        $this->actingAs($a)->getJson("/api/v1/leagues/{$id}/draw")->assertOk()->assertJsonCount(3, 'owners');
    }

    public function test_unknown_players_or_more_players_than_teams_are_refused(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create(['username' => 'boss']);
        User::factory()->create(['username' => 'ali']);
        User::factory()->create(['username' => 'omar']);
        Wallet::post($owner->id, 'daily', 1000, 'test-grant');
        $this->actingAs($owner)->postJson('/api/v1/leagues', $this->settings(['team_count' => 2, 'entry_mode' => 'draw', 'club_id' => null, 'draw_users' => ['nobody']]))->assertStatus(422);
        $this->actingAs($owner)->postJson('/api/v1/leagues', $this->settings(['team_count' => 2, 'entry_mode' => 'draw', 'club_id' => null, 'draw_users' => ['ali', 'omar']]))->assertStatus(422);
        $this->assertSame(0, DB::table('leagues')->count());
    }
}
