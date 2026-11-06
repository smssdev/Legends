<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 43 W1] The contract a coach signs with his club, once a season: its club, objective and money. */
class LeagueContractTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_contract_waits_for_the_signature_once_a_season(): void
    {
        Carbon::setTestNow('2026-11-05 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $url = "/api/v1/leagues/{$league['id']}";

        $contract = $this->actingAs($owner)->getJson($url)->assertOk()->json('league.me.contract');
        $this->assertSame($league['my_club_id'], $contract['club']['id']);
        $this->assertSame(1, $contract['season']);
        $this->assertSame((int) DB::table('clubs')->where('id', $league['my_club_id'])->value('balance'), $contract['budget']);
        $goal = DB::table('club_objectives')->where('club_id', $league['my_club_id'])->where('competition', 'league')->first();
        $this->assertSame(['kind' => $goal->kind, 'target' => (int) $goal->target], $contract['objective']);

        // Signed: gone, and twice is once.
        $this->postJson("{$url}/contract")->assertOk();
        $this->postJson("{$url}/contract")->assertOk();
        $this->assertNull($this->getJson($url)->json('league.me.contract'));
        $this->assertSame(1, DB::table('league_contracts')->count());
        // Not a coach of this league.
        $this->actingAs(User::factory()->create())->postJson("{$url}/contract")->assertForbidden();
    }
}
