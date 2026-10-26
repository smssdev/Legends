<?php

namespace Tests\Feature\Concerns;

use App\League\LeagueTiers;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/** A small template of real-looking clubs, and a league made from it through the API. */
trait MakesLeagues
{
    /** How many teams a league has unless a test says (at least half its template's clubs [UP9]). */
    protected int $defaultTeams = 6;

    /** @return list<int> master club ids, strongest first */
    protected function template(int $clubs = 8, string $league = 'Test League', bool $full = false): array
    {
        $ids = [];
        for ($c = 0; $c < $clubs; $c++) {
            $ovr = 85 - $c;
            $id = DB::table('master_clubs')->insertGetId([
                'data_version' => '2026', 'name' => $league === 'Test League' ? "Club {$c}" : "{$league} {$c}", 'code' => sprintf('C%02d', $c), 'league_name' => $league,
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
            // [UP9, UP17] At least half the template's clubs (6 of its 8), one round a day, two days to get ready.
            'template' => 'Test League', 'team_count' => $this->defaultTeams, 'rounds_per_day' => 1, 'round_times' => ['21:00'],
            'prep_days' => 2, 'season_end_mode' => 'renew', 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString(),
            'starting_budget' => 3_000_000, 'fair_league' => true, 'integrity' => false,
            'club_id' => DB::table('master_clubs')->where('league_name', 'Test League')->orderByDesc('strength_cp')->value('id'),
        ];
    }

    /** Made through the API; a customized league is paid in coins [UP9], so the owner is given them first. */
    protected function makeLeague(User $owner, array $over = []): array
    {
        $settings = $this->settings($over);
        Wallet::post($owner->id, 'daily', LeagueTiers::cost((int) $settings['team_count']), 'test-grant:'.$owner->id.':'.Str::random(8));

        return $this->actingAs($owner)->postJson('/api/v1/leagues', $settings)->assertCreated()->json('league');
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
