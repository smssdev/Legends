<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 64 B7] Two coaches face to face on a profile: from their matches, no table of its own. */
class HeadToHeadTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_my_record_against_a_coach_on_his_profile(): void
    {
        $this->template();
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4]);
        $season = (int) DB::table('seasons')->where('league_id', $league['id'])->value('id');
        $mine = (int) $league['my_club_id'];
        $rival = $this->memberOutside($league, [$mine]);
        $theirs = (int) DB::table('league_memberships')->where('season_id', $season)->where('user_id', $rival->id)->value('club_id');
        $bot = (int) DB::table('clubs')->where('league_id', $league['id'])->whereNull('user_id')->whereNotIn('id', [$mine, $theirs])->value('id');
        $at = fn (int $d) => GameClock::now()->addDays($d);
        $row = fn (int $home, int $away, int $hg, int $ag, int $d) => [
            'season_id' => $season, 'competition' => 'league', 'round' => 30 + $d, 'scheduled_at' => $at($d), 'home_id' => $home, 'away_id' => $away,
            'is_bye' => false, 'status' => 'finished', 'home_goals' => $hg, 'away_goals' => $ag, 'created_at' => $at(0), 'updated_at' => $at(0),
        ];
        DB::table('fixtures')->insert([
            $row($mine, $theirs, 2, 0, 1),    // won
            $row($theirs, $mine, 1, 1, 2),    // drawn
            $row($theirs, $mine, 3, 1, 3),    // lost, the newest
            $row($mine, $bot, 5, 0, 4),       // a bot's club: not this rival
        ]);

        $this->actingAs($owner)->getJson("/api/v1/coaches/{$rival->id}")->assertOk()
            ->assertJsonPath('head_to_head', ['played' => 3, 'won' => 1, 'drawn' => 1, 'lost' => 1, 'last' => ['L', 'D', 'W']]);
        // From his side, the other way round; and none on one's own profile.
        $this->actingAs($rival)->getJson("/api/v1/coaches/{$owner->id}")->assertJsonPath('head_to_head.won', 1)->assertJsonPath('head_to_head.last', ['W', 'D', 'L']);
        $this->actingAs($owner)->getJson("/api/v1/coaches/{$owner->id}")->assertJsonPath('head_to_head', null);
    }
}
