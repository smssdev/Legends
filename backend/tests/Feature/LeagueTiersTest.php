<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [UP9] The owner's spec (4): the standard league is free, any change is paid once (clubs × 20 coins), half the clubs at least. */
class LeagueTiersTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(18);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function create(User $owner, array $over = []): TestResponse
    {
        return $this->actingAs($owner)->postJson('/api/v1/leagues', $over + ['template' => 'Test League', 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString(),
            'club_id' => DB::table('master_clubs')->orderByDesc('strength_cp')->value('id')]);
    }

    public function test_the_standard_league_is_free_with_every_club_two_days_and_one_round_at_the_creators_evening(): void
    {
        $owner = User::factory()->create();
        $league = $this->create($owner, ['timezone' => 'Asia/Dubai'])->assertCreated()->json('league');
        $row = DB::table('leagues')->where('id', $league['id'])->first();
        $this->assertSame([18, 2, 1, 0], [(int) $row->team_count, (int) $row->prep_days, (int) $row->rounds_per_day, (int) $row->custom_coins]);
        // 21:00 in Dubai is 20:00 in Cairo (the schedule's zone).
        $this->assertSame(['20:00'], json_decode($row->round_times, true));
        $this->assertSame([true, true, false, 'end'], [(bool) $row->integrity, (bool) $row->press_conferences, (bool) $row->fair_league, $row->season_end_mode]);
        $this->assertSame(0, Wallet::balance($owner->id));
    }

    public function test_a_customized_league_costs_its_clubs_times_twenty_once_and_nothing_without_the_coins(): void
    {
        $owner = User::factory()->create();
        // [Sprint 40 B2] Any number from two: one is not a league.
        $this->create($owner, ['team_count' => 1])->assertUnprocessable()->assertJsonValidationErrors('team_count');
        $this->create($owner, ['team_count' => 9, 'prep_days' => 4])->assertConflict()->assertJsonPath('message', 'رصيد الكوينز لا يكفي.');
        $this->assertSame(0, DB::table('leagues')->count());
        Wallet::post($owner->id, 'daily', 500, 'seed');
        $league = $this->create($owner, ['team_count' => 9, 'prep_days' => 4])->assertCreated()->json('league');
        $this->assertSame(500 - 9 * 20, Wallet::balance($owner->id));
        $this->assertSame(180, (int) DB::table('leagues')->where('id', $league['id'])->value('custom_coins'));
        // Already customized: further changes before the start cost nothing more.
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['press_conferences' => false, 'round_times' => ['22:00']])->assertOk();
        $this->assertSame(320, Wallet::balance($owner->id));
    }

    public function test_changing_a_free_league_before_the_start_makes_it_customized(): void
    {
        $owner = User::factory()->create();
        $league = $this->create($owner)->assertCreated()->json('league');
        // Its name and start are free to change.
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['name' => 'دوري الشلة'])->assertOk();
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['fair_league' => true])->assertConflict();
        Wallet::post($owner->id, 'daily', 400, 'seed');
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['fair_league' => true])->assertOk()->assertJsonPath('league.fair_league', true);
        $this->assertSame(400 - 18 * 20, Wallet::balance($owner->id));
        $this->assertSame(Wallet::sum($owner->id), Wallet::balance($owner->id));
    }
}
