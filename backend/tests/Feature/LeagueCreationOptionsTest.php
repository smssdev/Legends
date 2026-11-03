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

/** [Sprint 40 B1 to B3] A league from two teams, with no preparation, and its group from its first minute. */
class LeagueCreationOptionsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    /** A development league of this many teams, started now, played to its end by the server's own minutes. */
    private function season(int $teams, int $prep = 1): array
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => $teams, 'is_dev' => true, 'prep_days' => $prep, 'season_end_mode' => 'end',
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        for ($i = 0; $i < 3000 && DB::table('leagues')->where('id', $league['id'])->value('status') !== 'finished'; $i++) {
            Carbon::setTestNow(GameClock::now()->addSeconds(15));
            $this->artisan('matches:prepare');
            MatchRunner::step();
            $this->artisan('seasons:close');
        }

        return [$owner, $league];
    }

    public function test_a_league_of_two_teams_plays_its_season_and_cup(): void
    {
        [, $league] = $this->season(2);
        $this->assertSame('finished', DB::table('leagues')->where('id', $league['id'])->value('status'));
        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        $this->assertSame(2, DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('is_bye', false)->count());
        $this->assertSame(1, DB::table('titles')->where('season_id', $season)->where('competition', 'cup')->where('position', 1)->count());
    }

    public function test_a_league_of_three_teams_plays_its_season(): void
    {
        [, $league] = $this->season(3);
        $this->assertSame('finished', DB::table('leagues')->where('id', $league['id'])->value('status'));
    }

    public function test_no_preparation_the_first_round_on_the_first_day(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['prep_days' => 0, 'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->assertSame(0, $league['prep_days']);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $first = DB::table('fixtures')->where('competition', 'league')->orderBy('scheduled_at')->value('scheduled_at');
        // Today at 21:00 in Cairo, the round's time, with no day to get ready.
        $this->assertSame('2026-10-22', Carbon::parse($first, 'UTC')->setTimezone('Africa/Cairo')->toDateString());
        // And 1 or 3 days are not offered.
        $this->actingAs(User::factory()->create())->postJson('/api/v1/leagues', $this->settings(['prep_days' => 3]))->assertStatus(422);
    }

    public function test_the_group_is_there_from_the_league_s_first_minute_until_it_ends(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 2]);
        $group = (int) DB::table('chat_groups')->where('league_id', $league['id'])->value('id');
        $this->assertGreaterThan(0, $group);
        $this->assertTrue(DB::table('chat_group_members')->where('chat_group_id', $group)->where('user_id', $owner->id)->exists());
        // A coach who takes a team is in it at once, before the league starts.
        $coach = $this->approvedCoach($owner, $league);
        $club = DB::table('clubs')->where('league_id', $league['id'])->whereNull('user_id')->value('id');
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated();
        $this->assertTrue(DB::table('chat_group_members')->where('chat_group_id', $group)->where('user_id', $coach->id)->exists());
        $this->postJson("/api/v1/groups/{$group}/messages", ['body' => 'أهلاً'])->assertSuccessful();
        // Once the league ends, it is kept to read.
        DB::table('leagues')->where('id', $league['id'])->update(['status' => 'finished']);
        $this->postJson("/api/v1/groups/{$group}/messages", ['body' => 'مرحباً'])->assertStatus(409);
        $this->getJson("/api/v1/groups/{$group}")->assertOk()->assertJsonPath('group.closed', true);
    }
}
