<?php

namespace Tests\Unit;

use App\Engine\MatchSetup;
use App\Simulator\Commentary;
use App\Simulator\Runner;
use Tests\TestCase;

/** The text commentary [Sprint 20 B1, D1]: the template table, picked by context and seeded. */
class CommentaryTest extends TestCase
{
    private function state(int $seed): array
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        $squad = fn (int $base, int $ovr) => array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P{$base}x{$i}", 'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
            'overall' => $ovr - intdiv($i, 3), 'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70,
            'gk_diving' => 75, 'gk_handling' => 75, 'gk_positioning' => 75, 'gk_reflexes' => 75,
            'penalties' => 70, 'free_kick' => 65, 'crossing' => 65, 'heading' => 65, 'stamina' => 75, 'aggression' => 70,
        ], $positions, array_keys($positions));
        $club = fn ($id) => ['id' => $id, 'name' => "النادي{$id}", 'code' => 'C'.$id, 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];

        return MatchSetup::build(['club' => $club(1), 'squad' => $squad(100, 84)], ['club' => $club(2), 'squad' => $squad(200, 78)],
            ['seed' => $seed, 'competition' => 'cup'], ['match' => config('game.match'), 'engine' => config('game.engine')]);
    }

    /** Every minute of a match, each with its commentary. */
    private function play(int $seed): array
    {
        $state = $this->state($seed);
        $out = [];
        while (! $state['finished']) {
            $state = Runner::tick($state);
            $out[] = Commentary::annotate($state, $state['out']);
        }

        return $out;
    }

    public function test_the_table_has_at_least_250_lines_with_known_placeholders_only(): void
    {
        $table = Commentary::table();
        $this->assertGreaterThanOrEqual(250, array_sum(array_map('count', $table)));
        foreach ($table as $key => $lines) {
            $this->assertNotEmpty($lines, $key);
            foreach ($lines as $line) {
                preg_match_all('/\{(\w+)\}/u', $line, $m);
                $this->assertEmpty(array_diff($m[1], ['p', 'q', 'A', 'B', 'n', 'd', 's']), "{$key}: {$line}");
            }
        }
        // A goal without an assist never names one.
        foreach ($table['goal.solo'] as $line) {
            $this->assertStringNotContainsString('{q}', $line);
        }
    }

    public function test_every_key_the_commentator_asks_for_is_in_the_table(): void
    {
        $code = file_get_contents(app_path('Simulator/Commentary.php'));
        $table = Commentary::table();
        // The fixed keys (with a dot); the built ones (attack.{result}...) are checked by playing matches below.
        preg_match_all("/'((?:attack|goal|score|card|sub|action|stoppage)\\.[a-z_]+(?:\\.[a-z_]+)*)'/", $code, $m);
        $this->assertNotEmpty($m[1]);
        foreach (array_unique($m[1]) as $key) {
            // A prefix (goal.late) names a family of keys.
            $family = array_filter(array_keys($table), fn ($k) => str_starts_with($k, $key.'.'));
            $this->assertTrue(isset($table[$key]) || $family, $key);
        }
        foreach (['goal', 'foul', 'corner', 'injury', 'sub', 'stoppage', 'shootout'] as $key) {
            $this->assertArrayHasKey($key, $table);
        }
    }

    public function test_every_telling_event_of_many_matches_gets_a_full_line(): void
    {
        $told = [];
        foreach (range(1, 40) as $seed) {
            foreach ($this->play($seed * 7919) as $tick) {
                foreach ($tick['events'] as $e) {
                    $must = in_array($e['type'], ['goal', 'card', 'sub', 'injury', 'stoppage', 'shootout', 'corner', 'penalty', 'free_kick'], true)
                        || ($e['type'] === 'period') || ($e['type'] === 'attack' && ! in_array($e['result'], ['goal', 'penalty', 'foul'], true));
                    if ($must) {
                        $this->assertArrayHasKey('text', $e, json_encode($e));
                    }
                    if (isset($e['text'])) {
                        $this->assertDoesNotMatchRegularExpression('/\{\w+\}|لـ\s|لـال|  /u', $e['text']);
                        $told[$e['text']] = true;
                    }
                }
            }
        }
        // The seed spreads the variants: many different lines, not the first of each key.
        $this->assertGreaterThan(150, count($told));
    }

    public function test_the_same_minute_always_reads_the_same(): void
    {
        $a = array_map(fn ($t) => array_column($t['events'], 'text'), $this->play(4242));
        $b = array_map(fn ($t) => array_column($t['events'], 'text'), $this->play(4242));
        $this->assertSame($a, $b);
        $this->assertNotSame($a, array_map(fn ($t) => array_column($t['events'], 'text'), $this->play(4243)));
    }

    public function test_the_lines_never_read_the_tactics(): void
    {
        $state = $this->state(99);
        while (! $state['finished']) {
            $state = Runner::tick($state);
            $other = $state;
            foreach (['home', 'away'] as $side) {
                $other['teams'][$side]['tactics'] = ['pressing' => 1, 'style' => 99, 'tempo' => 1, 'plan' => 'long', 'att' => 'back', 'mid' => 'def', 'def' => 'mid', 'trap' => 1, 'marking' => 'man', 'tackling' => 3];
            }
            $this->assertSame(Commentary::annotate($state, $state['out']), Commentary::annotate($other, $state['out']));
        }
    }
}
