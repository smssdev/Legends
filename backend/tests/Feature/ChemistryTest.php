<?php

namespace Tests\Feature;

use App\Engine\MatchSetup;
use App\League\Chemistry;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X22] The eleven's chemistry: links to the two nearest team-mates, coloured by nationality, club, league and matches together. */
class ChemistryTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    /** A back four and a keeper, in a line across the pitch. */
    private function slots(): array
    {
        return array_map(fn ($y) => ['x' => 260, 'y' => $y], [100, 250, 400, 550, 700]);
    }

    public function test_links_take_their_colour_from_nation_club_league_and_matches_together(): void
    {
        $info = [
            1 => ['nat' => 'Egypt', 'club' => 7, 'league' => 'A'],
            2 => ['nat' => 'Egypt', 'club' => 7, 'league' => 'A'],   // with 1: green
            3 => ['nat' => 'Spain', 'club' => 7, 'league' => 'A'],   // with 2: yellow (the league)
            4 => ['nat' => 'Spain', 'club' => 9, 'league' => 'B'],   // with 3: yellow (the nation)
            5 => ['nat' => 'Ghana', 'club' => 8, 'league' => 'C'],   // with 4: red
        ];
        $r = Chemistry::score([1, 2, 3, 4, 5], $this->slots(), $info, []);
        $colors = collect($r['links'])->mapWithKeys(fn ($l) => ["{$l['a']}-{$l['b']}" => $l['color']]);
        $this->assertSame('green', $colors['1-2']);
        $this->assertSame('yellow', $colors['2-3']);
        $this->assertSame('yellow', $colors['3-4']);
        $this->assertSame('red', $colors['4-5']);
        $this->assertSame(intdiv(collect($r['links'])->sum(fn ($l) => config('game.chemistry.link_value')[$l['color']]), count($r['links'])), $r['score']);

        // Fifteen matches together make any link green.
        $together = Chemistry::score([1, 2, 3, 4, 5], $this->slots(), $info, ['4-5' => 15]);
        $this->assertSame('green', collect($together['links'])->first(fn ($l) => $l['a'] === 4 && $l['b'] === 5)['color']);
        $this->assertGreaterThan($r['score'], $together['score']);
    }

    public function test_one_nation_from_one_club_is_full_chemistry_and_strangers_are_low(): void
    {
        $same = array_fill_keys(range(1, 5), ['nat' => 'Egypt', 'club' => 7, 'league' => 'A']);
        $this->assertSame(100, Chemistry::score([1, 2, 3, 4, 5], $this->slots(), $same, [])['score']);

        $strangers = [];
        foreach (range(1, 5) as $i) {
            $strangers[$i] = ['nat' => "N{$i}", 'club' => $i, 'league' => "L{$i}"];
        }
        $low = Chemistry::score([1, 2, 3, 4, 5], $this->slots(), $strangers, []);
        $this->assertSame(config('game.chemistry.link_value.red'), $low['score']);
        $this->assertLessThan(50, $low['score']);
        // An empty slot is no one's neighbour.
        $this->assertSame(100, Chemistry::score([1, null, 3, 4, 5], $this->slots(), $same, [])['score']);
    }

    public function test_the_lineup_shows_the_chemistry(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $team = $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}/team")->assertOk()->json('lineup');
        $chem = $team['chemistry'];
        $this->assertGreaterThanOrEqual(0, $chem['score']);
        $this->assertLessThanOrEqual(100, $chem['score']);
        $this->assertGreaterThanOrEqual(10, count($chem['links']));
        $starters = array_filter($team['starters']);
        foreach ($chem['links'] as $l) {
            $this->assertContains($l['color'], ['green', 'yellow', 'red']);
            $this->assertContains($l['a'], $starters);
            $this->assertContains($l['b'], $starters);
        }
        Carbon::setTestNow();
    }

    public function test_the_engine_takes_the_chemistry_only_when_measured(): void
    {
        $side = fn (?int $chem) => ['club' => ['id' => 1], 'squad' => $this->squad()] + ($chem === null ? [] : ['chem' => $chem]);
        $cfg = ['match' => config('game.match'), 'engine' => config('game.engine')];
        $state = MatchSetup::build($side(140), $side(null), ['seed' => 1], $cfg);
        $this->assertSame(100, $state['teams']['home']['chem']);
        // The simulator measures nothing: its states keep their shape.
        $this->assertArrayNotHasKey('chem', $state['teams']['away']);
    }

    private function squad(): array
    {
        $lines = ['gk', 'def', 'def', 'def', 'def', 'mid', 'mid', 'mid', 'mid', 'att', 'att', 'gk', 'def', 'mid', 'att', 'def', 'mid', 'att'];
        $pos = ['gk' => 'GK', 'def' => 'CB', 'mid' => 'CM', 'att' => 'ST'];

        return array_map(fn ($i) => ['id' => $i + 1, 'name' => "P{$i}", 'position' => $pos[$lines[$i]], 'line' => $lines[$i], 'age' => 25, 'overall' => 70],
            array_keys($lines));
    }
}
