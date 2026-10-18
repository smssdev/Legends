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
}
