<?php

namespace Tests\Unit;

use App\Engine\MatchSetup;
use App\League\MatchFacts;
use App\League\MatchReport;
use App\League\Readings;
use App\Simulator\MatchChoreographer;
use App\Simulator\Runner;
use Tests\TestCase;

/**
 * The privacy of the readings and the report [ENGINE 8.1, 8.2, Sprint 20 B2]: their input carries no tactics,
 * so the other side's hidden values cannot reach them; and the pitch draws no side's line from them.
 */
class MatchFactsTest extends TestCase
{
    private const HIDDEN = ['tactics', 'pressing', 'style', 'tempo', 'att', 'mid', 'def', 'marking', 'trap', 'tackling', 'plan', 'a', 'takers'];

    private function state(int $seed, array $awayTactics = []): array
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        $squad = fn (int $base) => array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P{$base}x{$i}", 'position' => $pos, 'line' => $lines[$pos], 'age' => 24,
            'overall' => 80 - intdiv($i, 3), 'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70,
        ], $positions, array_keys($positions));
        $club = fn ($id) => ['id' => $id, 'name' => "C{$id}", 'code' => "C{$id}", 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];

        return MatchSetup::build(['club' => $club(1), 'squad' => $squad(100)], ['club' => $club(2), 'squad' => $squad(200), 'tactics' => $awayTactics],
            ['seed' => $seed], ['match' => config('game.match'), 'engine' => config('game.engine')]);
    }

    private function keys(array $a): array
    {
        $keys = [];
        foreach ($a as $k => $v) {
            $keys[] = (string) $k;
            if (is_array($v)) {
                $keys = [...$keys, ...$this->keys($v)];
            }
        }

        return $keys;
    }

    public function test_match_facts_hold_no_tactics_of_either_side(): void
    {
        [$state] = Runner::toEnd($this->state(31));
        foreach (['home', 'away'] as $side) {
            $this->assertEmpty(array_intersect(self::HIDDEN, $this->keys(MatchFacts::of($state, $side))), $side);
        }
    }

    public function test_the_other_sides_hidden_tactics_never_change_a_reading_or_the_report(): void
    {
        // The same match, with the away side's hidden values swapped after the kick-off: only what they did counts.
        $a = $this->state(77);
        $said = ['a' => [], 'b' => []];
        while (! $a['finished']) {
            $a = Runner::tick($a);
            $b = $a;
            $b['teams']['away']['tactics'] = ['pressing' => 99, 'style' => 1, 'tempo' => 99, 'att' => 'back', 'mid' => 'def', 'def' => 'mid', 'marking' => 'man', 'trap' => 1] + $a['teams']['away']['tactics'];
            [$ra, $said['a']] = Readings::next(MatchFacts::of($a, 'home'), $a['out']['events'], $said['a']);
            [$rb, $said['b']] = Readings::next(MatchFacts::of($b, 'home'), $a['out']['events'], $said['b']);
            $this->assertSame($ra, $rb);
            // Nor the pitch: the shapes come from the formation only.
            $this->assertSame(MatchChoreographer::frames($a, $a['out'], [525, 340]), MatchChoreographer::frames($b, $a['out'], [525, 340]));
        }
        $this->assertSame(MatchReport::build(MatchFacts::of($a, 'home'), []), MatchReport::build(MatchFacts::of($b, 'home'), []));
    }

    public function test_readings_come_about_every_fifteen_minutes_and_at_once_after_a_goal(): void
    {
        $state = $this->state(5);
        $said = [];
        $got = [];
        while (! $state['finished']) {
            $state = Runner::tick($state);
            [$r, $said] = Readings::next(MatchFacts::of($state, 'home'), $state['out']['events'], $said);
            if ($r) {
                $got[] = $r;
            }
            if (collect($state['out']['events'])->contains('type', 'goal')) {
                $this->assertNotNull($r, 'a goal is read at once');
                $this->assertStringStartsWith($state['out']['events'][array_search('goal', array_column($state['out']['events'], 'type'))]['team'] === 'home' ? 'goal_for' : 'goal_against', $r['kind']);
            }
        }
        $this->assertGreaterThanOrEqual(3, count($got));
        $this->assertLessThanOrEqual(16, count($got));
        foreach ($got as $r) {
            $this->assertDoesNotMatchRegularExpression('/\b[12] (مرة|مرات|تسديدات|فرص)/u', $r['text']);
        }
    }
}
