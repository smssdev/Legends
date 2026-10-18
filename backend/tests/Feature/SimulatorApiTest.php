<?php

namespace Tests\Feature;

use App\Engine\FloatGuard;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class SimulatorApiTest extends TestCase
{
    use RefreshDatabase;

    private function club(string $name, int $ovr): int
    {
        $id = DB::table('master_clubs')->insertGetId([
            'data_version' => 'test', 'name' => $name, 'code' => strtoupper(substr($name, 0, 3)), 'league_name' => 'Test League',
            'strength_cp' => $ovr * 100, 'color_primary' => '#C8102E', 'color_secondary' => '#FFFFFF',
        ]);
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid', 'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        foreach ($positions as $i => $pos) {
            DB::table('master_players')->insert([
                'data_version' => 'test', 'external_id' => $id * 100 + $i, 'master_club_id' => $id, 'name' => "$name $i",
                'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i, 'overall' => $ovr - intdiv($i, 3), 'potential' => $ovr,
                'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70, 'gk_diving' => 75, 'gk_handling' => 75,
                'gk_kicking' => 70, 'gk_positioning' => 75, 'gk_reflexes' => 75, 'penalties' => 70, 'free_kick' => 65, 'crossing' => 65,
                'heading' => 65, 'stamina' => 75, 'aggression' => 60,
            ]);
        }

        return $id;
    }

    public function test_a_full_simulator_match_with_an_order(): void
    {
        $home = $this->club('Alpha', 82);
        $away = $this->club('Beta', 79);

        $this->getJson('/api/v1/sim/clubs?q=Alp')->assertOk()->assertJsonPath('0.name', 'Alpha');
        $this->getJson("/api/v1/sim/clubs/$home")->assertOk()->assertJsonCount(11, 'starters');

        $match = $this->postJson('/api/v1/sim/matches', [
            'home_id' => $home, 'away_id' => $away, 'seed' => 77, 'control' => ['home' => 'me', 'away' => 'cpu'],
            'home' => ['tactics' => ['pressing' => 70, 'plan' => 'wings']],
        ])->assertCreated()->assertJsonPath('teams.home.tactics.pressing', 70)->json();

        $first = $this->postJson("/api/v1/sim/matches/{$match['id']}/ticks")->assertOk()->json('ticks.0');
        $this->assertCount(6, $first['frames']);
        $this->assertCount(22, $first['frames'][0]['p']);
        FloatGuard::check($first);

        $order = $this->postJson("/api/v1/sim/matches/{$match['id']}/actions", [
            'type' => 'tactics', 'team' => 'home', 'tactics' => ['style' => 80], 'idempotency_key' => 'k1',
        ])->assertStatus(202)->json();
        $this->assertSame(2, $order['target_tick']);
        $this->postJson("/api/v1/sim/matches/{$match['id']}/actions", [
            'type' => 'tactics', 'team' => 'home', 'tactics' => ['style' => 80], 'idempotency_key' => 'k1',
        ])->assertOk()->assertJsonPath('duplicate', true);

        $second = $this->postJson("/api/v1/sim/matches/{$match['id']}/ticks")->json('ticks.0');
        $this->assertSame(80, $second['teams']['home']['tactics']['style']);
        $this->assertSame('action', $second['events'][0]['type']);

        $this->getJson("/api/v1/sim/matches/{$match['id']}/report")->assertStatus(409);
        $rest = $this->postJson("/api/v1/sim/matches/{$match['id']}/ticks", ['count' => 200])->json('ticks');
        $this->assertTrue(end($rest)['finished']);

        $report = $this->getJson("/api/v1/sim/matches/{$match['id']}/report")->assertOk()->json();
        $this->assertNotEmpty($report['reasons']);
        $this->assertNotNull($report['man_of_the_match']);
    }

    public function test_the_simulator_is_hidden_when_disabled(): void
    {
        config(['game.simulator.enabled' => false]);
        $this->getJson('/api/v1/sim/leagues')->assertNotFound();
    }
}
