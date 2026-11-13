<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X61 E3] The youth academy: the same prospects all the period, the potential hidden, two signings a season. */
class AcademyTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_prospects_are_young_the_same_all_the_period_and_two_can_be_signed_a_season(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        // Young players outside the league for the academy to find.
        $outside = DB::table('master_players')->whereNotIn('id', DB::table('players')->where('league_id', $league['id'])->select('master_player_id'))->limit(12)->pluck('id');
        DB::table('master_players')->whereIn('id', $outside)->update(['age' => 18]);
        $url = "/api/v1/leagues/{$league['id']}/market/academy";

        $a = $this->actingAs($owner)->getJson($url)->assertOk()
            // [Sprint 59 F1] The fields the app reads through Academy (openapi.yaml).
            ->assertJsonStructure(['renews_at', 'signed', 'per_season', 'prospects' => ['*' => ['id', 'name', 'position', 'line', 'age', 'overall', 'potential_from', 'potential_to', 'price', 'nationality']]])->json();
        $this->assertCount(3, $a['prospects']);
        foreach ($a['prospects'] as $p) {
            $this->assertLessThanOrEqual(19, $p['age']);
            $this->assertLessThanOrEqual($p['potential_to'], $p['potential_from'] + 8);
            $this->assertArrayNotHasKey('potential', $p);
        }
        $this->assertSame($a['prospects'], $this->getJson($url)->json('prospects'));

        $this->postJson($url, ['master_player_id' => 999999])->assertNotFound();
        $first = $a['prospects'][0];
        $balance = (int) DB::table('clubs')->where('id', $league['my_club_id'])->value('balance');
        $after = $this->postJson($url, ['master_player_id' => $first['id']])->assertOk()->json();
        $this->assertSame(1, $after['signed']);
        $this->assertTrue(DB::table('players')->where('club_id', $league['my_club_id'])->where('master_player_id', $first['id'])->exists());
        $this->assertSame($balance - $first['price'], (int) DB::table('clubs')->where('id', $league['my_club_id'])->value('balance'));
        $this->assertSame((int) DB::table('clubs')->where('id', $league['my_club_id'])->value('balance'), ClubLedger::sum($league['my_club_id']));
        $this->assertNotContains($first['id'], array_column($after['prospects'], 'id'));
        // [X99] A signing only frees its own place: the other prospects stay, one new one fills the gap.
        foreach (array_slice($a['prospects'], 1) as $stay) {
            $this->assertContains($stay['id'], array_column($after['prospects'], 'id'));
        }
        $this->assertCount(3, $after['prospects']);

        $this->postJson($url, ['master_player_id' => $after['prospects'][0]['id']])->assertOk();
        $third = $this->getJson($url)->json('prospects.0.id');
        $this->postJson($url, ['master_player_id' => $third])->assertConflict();

        // Another period, other prospects.
        Carbon::setTestNow(GameClock::now()->addDays(3));
        $this->assertNotSame(array_column($a['prospects'], 'id'), array_column($this->getJson($url)->json('prospects'), 'id'));
        $this->actingAs(User::factory()->create())->getJson($url)->assertForbidden();
    }
}
