<?php

namespace Tests\Feature;

use App\Engine\FloatGuard;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
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

    public function test_a_live_match_runs_on_the_server_clock_for_both_screens(): void
    {
        Carbon::setTestNow('2026-10-18 12:00:00');
        config(['game.match.moment_ms' => null, 'game.match.minute_ms' => null, 'game.match.broadcast_ms' => null, 'game.match.kickoff_ms' => 3000]); // fixed 3 s minutes and a 3 s kick-off keep the arithmetic simple
        $home = $this->club('Alpha', 82);
        $away = $this->club('Beta', 79);
        $made = $this->postJson('/api/v1/sim/matches', ['home_id' => $home, 'away_id' => $away, 'seed' => 5, 'mode' => 'live'])
            ->assertCreated()->assertJsonPath('mode', 'live')->assertJsonPath('started', false)->assertJsonPath('you', 'home')
            ->assertJsonPath('control', ['home' => 'me', 'away' => 'me'])->json();
        $id = $made['id'];
        $away_seat = ['X-Seat' => $made['seats']['away']];

        // Nothing moves before the start, and nobody can drive the clock by hand.
        $this->getJson("/api/v1/sim/matches/$id/live")->assertOk()->assertJsonPath('started', false)->assertJsonCount(0, 'ticks');
        $this->postJson("/api/v1/sim/matches/$id/ticks")->assertStatus(409);

        $this->postJson("/api/v1/sim/matches/$id/start")->assertForbidden();
        $this->postJson("/api/v1/sim/matches/$id/start", [], $away_seat)->assertOk()->assertJsonPath('started', true);
        $this->getJson("/api/v1/sim/matches/$id/live")->assertJsonCount(0, 'ticks');

        // 3 s countdown + one minute (3 s): two minutes are due.
        Carbon::setTestNow('2026-10-18 12:00:06');
        $this->postJson("/api/v1/sim/matches/$id/actions", ['type' => 'tactics', 'team' => 'away', 'tactics' => ['style' => 80], 'idempotency_key' => 'a1'], $away_seat)
            ->assertStatus(202)->assertJsonPath('target_tick', 1);
        $a = $this->getJson("/api/v1/sim/matches/$id/live?since=0", $away_seat)->assertOk()->json();
        $this->assertSame([1, 2], array_column($a['ticks'], 'tick'));
        $this->assertCount(6, $a['ticks'][0]['frames']);
        $this->assertSame(80, $a['ticks'][0]['teams']['away']['tactics']['style']);
        $this->assertSame(3000, $a['ticks'][0]['moment']['ms']);
        // Each minute carries its start on the server clock, so both screens play it together.
        $this->assertSame([3000, 6000], array_map(fn ($t) => $t['at'] - $a['ticks'][0]['at'] + 3000, $a['ticks']));

        // The second screen asks at the same moment: same minutes, nothing simulated twice.
        $b = $this->getJson("/api/v1/sim/matches/$id/live?since=1")->json();
        $this->assertSame([2], array_column($b['ticks'], 'tick'));
        $this->assertSame(2, $b['tick']);
        // A viewer without a seat sees neither side's tactics.
        $this->assertNull($b['ticks'][0]['teams']['away']['tactics']);

        // Far behind: the match catches up to the end, and the buffer says it skipped.
        Carbon::setTestNow('2026-10-18 13:00:00');
        $end = $this->getJson("/api/v1/sim/matches/$id/live?since=2")->json();
        $this->assertTrue($end['finished']);
        $this->assertTrue($end['gap']);
        $this->getJson("/api/v1/sim/matches/$id/report")->assertOk();
        Carbon::setTestNow();
    }

    public function test_two_friends_meet_in_a_room_and_the_match_kicks_off(): void
    {
        Carbon::setTestNow('2026-10-19 12:00:00');
        $home = $this->club('Alpha', 82);
        $away = $this->club('Beta', 79);
        $opened = $this->postJson('/api/v1/sim/rooms', ['name' => 'سليمان', 'club_id' => $home])
            ->assertCreated()->assertJsonPath('host.name', 'سليمان')->assertJsonPath('guest', null)->assertJsonPath('match_id', null)->json();
        $room = $opened['id'];

        // The guest cannot take the host's club.
        $this->postJson("/api/v1/sim/rooms/$room/join", ['name' => 'حمزة', 'club_id' => $home])->assertUnprocessable();

        $joined = $this->postJson("/api/v1/sim/rooms/$room/join", ['name' => 'حمزة', 'club_id' => $away])
            ->assertOk()->assertJsonPath('guest.name', 'حمزة')->assertJsonPath('guest.club.id', $away)->json();
        $this->assertNotNull($joined['match_id']);

        // The host's screen sees the match; it is live, started, and carries both names.
        $this->getJson("/api/v1/sim/rooms/$room")->assertJsonPath('match_id', $joined['match_id'])->assertJsonMissingPath('seat');
        $this->getJson('/api/v1/sim/matches/'.$joined['match_id'])->assertOk()
            ->assertJsonPath('mode', 'live')->assertJsonPath('started', true)
            ->assertJsonPath('coaches.home', 'سليمان')->assertJsonPath('coaches.away', 'حمزة');

        // Each friend's seat manages his own side only.
        $match = $joined['match_id'];
        $this->getJson("/api/v1/sim/matches/$match", ['X-Seat' => $opened['seat']])->assertJsonPath('you', 'home');
        $this->getJson("/api/v1/sim/matches/$match", ['X-Seat' => $joined['seat']])->assertJsonPath('you', 'away');

        // A second guest is turned away.
        $this->postJson("/api/v1/sim/rooms/$room/join", ['name' => 'آخر', 'club_id' => $away])->assertUnprocessable();
        Carbon::setTestNow();
    }

    public function test_in_a_live_match_each_coach_manages_only_his_side_and_cannot_see_the_other_tactics(): void
    {
        Carbon::setTestNow('2026-10-19 12:00:00');
        config(['game.match.kickoff_ms' => 3000]);
        $home = $this->club('Alpha', 82);
        $away = $this->club('Beta', 79);
        $made = $this->postJson('/api/v1/sim/matches', [
            'home_id' => $home, 'away_id' => $away, 'seed' => 9, 'mode' => 'live', 'away' => ['tactics' => ['pressing' => 90]],
        ])->assertCreated()->json();
        $id = $made['id'];
        $h = ['X-Seat' => $made['seats']['home']];
        $a = ['X-Seat' => $made['seats']['away']];

        // The home coach sees his tactics, never the away ones, even when they change.
        $this->assertNull($made['teams']['away']['tactics']);
        $this->getJson("/api/v1/sim/matches/$id", $h)->assertJsonPath('you', 'home')->assertJsonPath('teams.away.tactics', null)->assertJsonPath('teams.home.tactics.plan', $made['teams']['home']['tactics']['plan']);
        $this->getJson("/api/v1/sim/matches/$id", $a)->assertJsonPath('you', 'away')->assertJsonPath('teams.away.tactics.pressing', 90)->assertJsonPath('teams.home.tactics', null);

        // Orders for the friend's side are refused: without a seat, with the other seat, or with a made-up one.
        $order = fn ($team, $key) => ['type' => 'tactics', 'team' => $team, 'tactics' => ['style' => 10], 'idempotency_key' => $key];
        $this->postJson("/api/v1/sim/matches/$id/actions", $order('away', 'x1'))->assertForbidden();
        $this->postJson("/api/v1/sim/matches/$id/actions", $order('away', 'x2'), $h)->assertForbidden();
        $this->postJson("/api/v1/sim/matches/$id/actions", $order('away', 'x3'), ['X-Seat' => 'guess'])->assertForbidden();
        $this->postJson("/api/v1/sim/matches/$id/actions", $order('away', 'a1'), $a)->assertStatus(202);

        $this->postJson("/api/v1/sim/matches/$id/start", [], $h)->assertOk();
        Carbon::setTestNow('2026-10-19 12:00:04');
        $ticks = $this->getJson("/api/v1/sim/matches/$id/live", $h)->json('ticks');
        $first = $ticks[0];
        $this->assertNull($first['teams']['away']['tactics']);
        $action = collect($first['events'])->firstWhere('type', 'action');
        $this->assertSame('away', $action['team']);
        $this->assertArrayNotHasKey('tactics', $action['action']);
        $this->assertSame(10, $this->getJson("/api/v1/sim/matches/$id/live", $a)->json('ticks.0.teams.away.tactics.style'));
        Carbon::setTestNow();
    }

    public function test_a_live_match_stops_for_the_coachs_window_and_takes_changes_only_then(): void
    {
        Carbon::setTestNow('2026-10-19 12:00:00');
        config(['game.match.kickoff_ms' => 1000]);
        $made = $this->postJson('/api/v1/sim/matches', ['home_id' => $this->club('Alpha', 82), 'away_id' => $this->club('Beta', 79), 'seed' => 4, 'mode' => 'live'])->json();
        $id = $made['id'];
        $h = ['X-Seat' => $made['seats']['home']];
        $this->assertSame([15, 30, 60, 75], $made['timing']['windows']);
        $order = fn ($key) => ['type' => 'tactics', 'team' => 'home', 'tactics' => ['tempo' => 80], 'idempotency_key' => $key];
        $this->postJson("/api/v1/sim/matches/$id/start", [], $h)->assertOk();
        // Minute by minute up to the window after minute 15 [X42]: refused while the match plays.
        $window = null;
        for ($at = 0; ! $window && $at < 600; $at++) {
            Carbon::setTestNow(Carbon::parse('2026-10-19 12:00:00')->addSeconds($at));
            $ticks = $this->getJson("/api/v1/sim/matches/$id/live?since=0", $h)->json('ticks');
            $last = end($ticks);
            if ($last && $last['minute'] === [5, 0]) {
                $this->postJson("/api/v1/sim/matches/$id/actions", $order('k5'), $h)->assertStatus(409);
            }
            $window = collect($ticks)->firstWhere('window', true);
        }
        $this->assertSame([15, 0], $window['minute']);
        $this->postJson("/api/v1/sim/matches/$id/actions", $order('k15'), $h)->assertStatus(202)->assertJsonPath('target_tick', $window['tick'] + 1);
        Carbon::setTestNow();
    }

    public function test_a_live_minute_is_made_just_before_it_starts_and_its_result_waits_for_it(): void
    {
        Carbon::setTestNow('2026-10-19 12:00:00');
        config(['game.match.moment_ms' => null, 'game.match.minute_ms' => null, 'game.match.broadcast_ms' => null, 'game.match.live_lead_ms' => 1200, 'game.match.kickoff_ms' => 3000]);
        $made = $this->postJson('/api/v1/sim/matches', ['home_id' => $this->club('Alpha', 82), 'away_id' => $this->club('Beta', 79), 'seed' => 3, 'mode' => 'live'])->json();
        $id = $made['id'];
        $this->postJson("/api/v1/sim/matches/$id/start", [], ['X-Seat' => $made['seats']['home']]);

        // Kick-off at 3 s: at 2 s the first minute is ready, but it has not started yet.
        Carbon::setTestNow('2026-10-19 12:00:02');
        $r = $this->getJson("/api/v1/sim/matches/$id/live")->json();
        $this->assertSame([1], array_column($r['ticks'], 'tick'));
        $this->assertSame(0, $r['tick']);
        $this->assertSame(1000, $r['ticks'][0]['at'] - $r['server_now']);
        $this->getJson("/api/v1/sim/matches/$id")->assertJsonPath('tick', 0)->assertJsonPath('score', ['home' => 0, 'away' => 0]);
        Carbon::setTestNow();
    }

    public function test_coaches_react_in_a_live_match_and_both_screens_see_it(): void
    {
        Carbon::setTestNow('2026-10-19 12:00:00');
        $made = $this->postJson('/api/v1/sim/matches', ['home_id' => $this->club('Alpha', 82), 'away_id' => $this->club('Beta', 79), 'mode' => 'live'])->json();
        $id = $made['id'];
        $this->postJson("/api/v1/sim/matches/$id/reactions", ['key' => 'fire'])->assertForbidden();
        $this->postJson("/api/v1/sim/matches/$id/reactions", ['key' => 'nope'], ['X-Seat' => $made['seats']['away']])->assertUnprocessable();
        $this->postJson("/api/v1/sim/matches/$id/reactions", ['key' => 'fire'], ['X-Seat' => $made['seats']['away']])
            ->assertCreated()->assertJsonPath('side', 'away')->assertJsonPath('id', 1);
        // Too soon after the last one.
        $this->postJson("/api/v1/sim/matches/$id/reactions", ['key' => 'clap'], ['X-Seat' => $made['seats']['away']])->assertUnprocessable();
        $this->postJson("/api/v1/sim/matches/$id/reactions", ['key' => 'laugh'], ['X-Seat' => $made['seats']['home']])->assertCreated();

        $this->getJson("/api/v1/sim/matches/$id/live", ['X-Seat' => $made['seats']['home']])
            ->assertJsonPath('reactions.0.key', 'fire')->assertJsonPath('reactions.1.side', 'home');
        Carbon::setTestNow('2026-10-19 12:00:30');
        $this->getJson("/api/v1/sim/matches/$id/live")->assertJsonCount(0, 'reactions');
        Carbon::setTestNow();
    }
}
