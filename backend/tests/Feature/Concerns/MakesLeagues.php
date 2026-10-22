<?php

namespace Tests\Feature\Concerns;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/** A small template of real-looking clubs, and a league made from it through the API. */
trait MakesLeagues
{
    /** @return list<int> master club ids, strongest first */
    protected function template(int $clubs = 20, string $league = 'Test League', bool $full = false): array
    {
        $ids = [];
        for ($c = 0; $c < $clubs; $c++) {
            $ovr = 85 - $c;
            $id = DB::table('master_clubs')->insertGetId([
                'data_version' => '2026', 'name' => "Club {$c}", 'code' => sprintf('C%02d', $c), 'league_name' => $league,
                'strength_cp' => $ovr * 100, 'color_primary' => '#C8102E', 'color_secondary' => '#FFFFFF',
            ]);
            // Four players, or a whole squad of 18 (two keepers) for the lineup tests.
            $positions = $full ? ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'] : ['GK', 'CB', 'CM', 'ST'];
            $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid', 'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
            foreach ($positions as $i => $pos) {
                DB::table('master_players')->insert([
                    'data_version' => '2026', 'external_id' => $id * 100 + $i, 'master_club_id' => $id, 'name' => "Player {$c}-{$i}",
                    'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
                    'overall' => $full ? $ovr - intdiv($i, 3) : $ovr, 'potential' => $ovr + 2, 'value' => 1_000_000 + $c,
                    'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70, 'penalties' => 50 + $i, 'free_kick' => 60 - $i, 'crossing' => 40 + $i,
                ]);
            }
            $ids[] = $id;
        }

        return $ids;
    }

    protected function settings(array $over = []): array
    {
        return $over + [
            'template' => 'Test League', 'team_count' => 6, 'rounds_per_day' => 2, 'round_times' => ['18:00', '21:00'],
            'prep_days' => 1, 'season_end_mode' => 'renew', 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString(),
            'starting_budget' => 3_000_000, 'fair_league' => true,
            'club_id' => DB::table('master_clubs')->where('league_name', 'Test League')->orderByDesc('strength_cp')->value('id'),
        ];
    }

    protected function makeLeague(User $owner, array $over = []): array
    {
        return $this->actingAs($owner)->postJson('/api/v1/leagues', $this->settings($over))->assertCreated()->json('league');
    }

    /** A coach who asked with the code and was approved by the owner. */
    protected function approvedCoach(User $owner, array $league): User
    {
        $coach = User::factory()->create();
        $id = $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertCreated()->json('request.id');
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/requests/{$id}/approve")->assertOk();

        return $coach;
    }

    protected function botClub(int $leagueId): int
    {
        return (int) DB::table('clubs')->where('league_id', $leagueId)->whereNull('user_id')->orderBy('id')->value('id');
    }
}
