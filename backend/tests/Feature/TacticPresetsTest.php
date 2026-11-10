<?php

namespace Tests\Feature;

use App\League\Tactics;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 50 M12] The ready philosophies: one tap sets their keys, the coach's own keys win, and the screen knows which is on. */
class TacticPresetsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_preset_sets_its_keys_and_the_coach_keeps_the_last_word(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => GameClock::now()->addDays(3)->toIso8601ZuluString()]);
        $url = "/api/v1/leagues/{$league['id']}/team/tactics";

        $this->actingAs($owner)->getJson($url)->assertOk()->assertJsonPath('presets', array_keys(Tactics::PRESETS));
        $this->putJson($url, ['preset' => 'counter'])->assertOk()->assertJsonPath('preset', 'counter')
            ->assertJsonPath('tactics.plan', 'counter')->assertJsonPath('tactics.tempo', 80);
        // A key sent with it is the coach's own; changed after, the philosophy is no longer on.
        $this->putJson($url, ['preset' => 'high_press', 'pressing' => 70])->assertJsonPath('tactics.pressing', 70)->assertJsonPath('preset', null);
        $this->putJson($url, ['preset' => 'samba'])->assertUnprocessable();
    }
}
