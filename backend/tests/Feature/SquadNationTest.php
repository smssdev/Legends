<?php

namespace Tests\Feature;

use App\Data\Nations;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 46] Each squad player carries his national team's code and colours, for the app's flag chip. */
class SquadNationTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_each_player_has_his_nation_code_and_colours(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $players = $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}/team")->assertOk()->json('players');
        $this->assertNotEmpty($players);
        foreach ($players as $p) {
            $name = Nations::canonical($p['nationality']);
            if ($name === null) {
                $this->assertNull($p['nation']);

                continue;
            }
            $this->assertSame(Nations::info($name)['code'], $p['nation']['code']);
            $this->assertCount(2, $p['nation']['colors']);
        }
    }
}
