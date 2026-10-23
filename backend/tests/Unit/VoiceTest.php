<?php

namespace Tests\Unit;

use App\Engine\MatchSetup;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use App\Simulator\Voice;
use Tests\TestCase;

/** The commentator's line, drawn on the server [Sprint 35 B1]: valid against the shared table, and the same every time. */
class VoiceTest extends TestCase
{
    private function match(int $seed): array
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        $squad = fn (int $base, int $ovr) => array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P{$base}x{$i}", 'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
            'overall' => $ovr - intdiv($i, 3), 'penalties' => 70, 'free_kick' => 65, 'crossing' => 65, 'heading' => 65,
        ], $positions, array_keys($positions));
        $club = fn ($id) => ['id' => $id, 'name' => "C{$id}", 'code' => 'C'.$id, 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];
        $state = MatchSetup::build(['club' => $club(1), 'squad' => $squad(100, 84)], ['club' => $club(2), 'squad' => $squad(200, 78)],
            ['seed' => $seed, 'competition' => 'cup'], ['match' => config('game.match'), 'engine' => config('game.engine')]);
        $out = [];
        while (! $state['finished']) {
            $state = Runner::tick($state);
            $kind = MomentClock::moment($state['out']['events'], $state['cfg']['match'])['kind'];
            $out[] = [$state['out'], Voice::for($state['out']['events'], $kind, $seed, $state['out']['tick'])];
        }

        return $out;
    }

    public function test_every_line_is_in_the_table_with_valid_variants_and_names_it_has(): void
    {
        $table = Voice::lines();
        $seen = [];
        foreach ([3, 11, 42, 77] as $seed) {
            foreach ($this->match($seed) as [$out, $v]) {
                if (! $v) {
                    continue;
                }
                $seen[$v['line']] = true;
                $this->assertArrayHasKey($v['line'], $table);
                foreach (['pre', 'key', 'post'] as $slot) {
                    if (! isset($v['pick'][$slot])) {
                        continue;
                    }
                    [$en, $ar] = $v['pick'][$slot];
                    if ($en !== null) {
                        $text = $table[$v['line']][$slot]['en'][$en];
                        $this->assertTrue(! str_contains($text, '{p}') || $v['vars']['p'], $text);
                        $this->assertTrue(! str_contains($text, '{q}') || $v['vars']['q'], $text);
                    }
                    if ($ar !== null) {
                        $this->assertArrayHasKey($ar, $table[$v['line']][$slot]['ar']);
                    }
                }
                // A goal minute is told as a goal.
                if (collect($out['events'])->contains('type', 'goal')) {
                    $this->assertContains($v['line'], ['goal', 'header', 'penalty_goal', 'free_kick_goal']);
                }
            }
        }
        $this->assertArrayHasKey('goal', $seen + ['goal' => isset($seen['header'])]);
        $this->assertGreaterThanOrEqual(6, count($seen));
    }

    public function test_the_same_match_says_the_same_words_and_another_varies(): void
    {
        $a = array_column($this->match(5), 1);
        $this->assertSame($a, array_column($this->match(5), 1));
        $this->assertNotSame($a, array_column($this->match(6), 1));
    }
}
