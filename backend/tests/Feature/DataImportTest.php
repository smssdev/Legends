<?php

namespace Tests\Feature;

use App\Models\MasterClub;
use App\Models\MasterPlayer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DataImportTest extends TestCase
{
    use RefreshDatabase;

    private function import(): void
    {
        $this->artisan('data:import', ['--path' => base_path('tests/Fixtures/ea-fc26')])->assertSuccessful();
    }

    public function test_it_keeps_only_complete_squads_with_a_goalkeeper(): void
    {
        $this->import();

        // Liverpool: 20 outfield + 2 GK. Arsenal: no GK. Burnley: 6 players. Cup entry: not a league.
        $this->assertSame(['Liverpool'], MasterClub::pluck('name')->all());
        $this->assertSame(22, MasterPlayer::count());
    }

    public function test_players_carry_the_attributes_the_engine_needs(): void
    {
        $this->import();

        $this->assertSame(0, MasterPlayer::where('line', '<>', 'gk')->whereNull('pac')->count());
        $this->assertSame(0, MasterPlayer::where('line', 'gk')->whereNull('gk_reflexes')->count());
        $this->assertSame(['att', 'def', 'gk', 'mid'], MasterPlayer::distinct()->orderBy('line')->pluck('line')->all());
    }

    public function test_strength_is_the_average_of_the_best_18_and_reimport_replaces(): void
    {
        $this->import();
        $this->import();

        $club = MasterClub::sole();
        $best = $club->players()->orderByDesc('overall')->take(18)->pluck('overall');
        $this->assertSame(intdiv($best->sum() * 100, 18), $club->strength_cp);
        $this->assertSame('LIV', $club->code);
        $this->assertSame(22, MasterPlayer::count());
    }

    /**
     * [X34] The Arab leagues reach the live game with --add: the new clubs join, and every row already there keeps its
     * id (a running league's players point at them), even when the file has changed since.
     */
    public function test_adding_keeps_every_row_there_and_adds_only_new_clubs(): void
    {
        $this->import();
        $before = MasterPlayer::orderBy('id')->get(['id', 'overall'])->toArray();

        $dir = sys_get_temp_dir().'/legends-arab-'.uniqid();
        mkdir($dir);
        $head = ['id', 'overallRating', 'firstName', 'lastName', 'commonName', 'preferredFoot', 'position', 'alternatePositions', 'nationality',
            'team', 'leagueName', 'age', 'pac', 'sho', 'pas', 'dri', 'def', 'phy', 'gkDiving', 'gkHandling', 'gkKicking', 'gkPositioning',
            'gkReflexes', 'penalties', 'freeKickAccuracy', 'crossing', 'headingAccuracy', 'stamina', 'aggression', 'clubPrimary', 'clubSecondary'];
        $f = fopen("$dir/arab_players.csv", 'w');
        fputcsv($f, $head, escape: '');
        foreach (range(1, 20) as $i) {
            $gk = $i <= 2;
            fputcsv($f, [100000000 + $i, 70, '', "Player $i", "Player $i", 'Right', $gk ? 'GK' : 'CM', '', 'Egypt', 'Al Ahly',
                'Egyptian Premier League', 26, $gk ? '' : 70, $gk ? '' : 60, $gk ? '' : 70, $gk ? '' : 70, $gk ? '' : 60, $gk ? '' : 70,
                $gk ? 70 : '', $gk ? 70 : '', $gk ? 70 : '', $gk ? 70 : '', $gk ? 70 : '', 60, 55, 60, 60, 68, 65, '#E20E0E', '#FFFFFF'], escape: '');
        }
        fclose($f);

        $args = ['--path' => base_path('tests/Fixtures/ea-fc26'), '--arab' => $dir, '--add' => true];
        $this->artisan('data:import', $args)->assertSuccessful();
        $this->artisan('data:import', $args)->assertSuccessful();

        $this->assertSame(['Liverpool', 'Al Ahly'], MasterClub::orderBy('id')->pluck('name')->all());
        $this->assertSame($before, MasterPlayer::whereIn('id', array_column($before, 'id'))->orderBy('id')->get(['id', 'overall'])->toArray());
        $ahly = MasterClub::where('name', 'Al Ahly')->sole();
        $this->assertSame(['Egyptian Premier League', '#E20E0E'], [$ahly->league_name, $ahly->color_primary]);
        $this->assertSame(20, $ahly->players()->count());
        array_map('unlink', glob("$dir/*"));
        rmdir($dir);
    }
}
