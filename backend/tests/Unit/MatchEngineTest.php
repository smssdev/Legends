<?php

namespace Tests\Unit;

use App\Engine\MatchSetup;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use PHPUnit\Framework\TestCase;

class MatchEngineTest extends TestCase
{
    private function squad(int $base, int $ovr): array
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];

        return array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P$i", 'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
            'overall' => $ovr - intdiv($i, 3), 'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70,
            'gk_diving' => 75, 'gk_handling' => 75, 'gk_positioning' => 75, 'gk_reflexes' => 75,
            'penalties' => 70, 'free_kick' => 65, 'crossing' => 65, 'heading' => 65, 'stamina' => 75, 'aggression' => 60,
        ], $positions, array_keys($positions));
    }

    private function state(int $seed): array
    {
        $cfg = require __DIR__.'/../../config/game.php';
        $club = fn ($id) => ['id' => $id, 'name' => "C$id", 'code' => 'C'.$id, 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];

        return MatchSetup::build(
            ['club' => $club(1), 'squad' => $this->squad(100, 82)],
            ['club' => $club(2), 'squad' => $this->squad(200, 80)],
            ['seed' => $seed],
            ['match' => $cfg['match'], 'engine' => $cfg['engine']],
        );
    }

    public function test_same_seed_gives_the_same_match(): void
    {
        [$a, $ticksA] = Runner::toEnd($this->state(42));
        [$b, $ticksB] = Runner::toEnd($this->state(42));

        $this->assertSame($ticksA, $ticksB);
        $this->assertSame($a['score'], $b['score']);
        $this->assertTrue($a['finished']);
        $this->assertGreaterThanOrEqual(93, count($ticksA));
    }

    public function test_a_substitution_applies_at_the_next_minute_and_counts(): void
    {
        $state = Runner::tick($this->state(7));
        $team = $state['teams']['home'];
        $out = $team['players'][5]['id'];
        $in = $team['players'][12]['id'];

        $state = Runner::tick($state, [['type' => 'sub', 'team' => 'home', 'out' => $out, 'in' => $in]]);
        $players = array_column($state['teams']['home']['players'], null, 'id');

        $this->assertFalse($players[$out]['on']);
        $this->assertTrue($players[$in]['on']);
        $this->assertSame(1, $state['teams']['home']['subs_used']);
        $this->assertSame([], $state['out']['rejected']);
    }

    public function test_invalid_orders_are_rejected_and_change_nothing(): void
    {
        $state = Runner::tick($this->state(7), [
            ['type' => 'tactics', 'team' => 'home', 'tactics' => ['pressing' => 150]],
            ['type' => 'formation', 'team' => 'away', 'formation' => '2-2-6'],
        ]);

        $this->assertCount(2, $state['out']['rejected']);
        $this->assertSame(50, $state['teams']['home']['tactics']['pressing']);
    }

    public function test_cup_draws_are_decided(): void
    {
        foreach (range(1, 30) as $seed) {
            $s = $this->state($seed);
            $s['competition'] = 'cup';
            [$end] = Runner::toEnd($s);
            $h = $end['score']['home'] + ($end['shootout']['home'] ?? 0);
            $a = $end['score']['away'] + ($end['shootout']['away'] ?? 0);
            $this->assertNotSame($h, $a, "seed $seed");
        }
    }

    /** [X99] A shootout ends the moment one side cannot be caught, even between a pair of kicks, and not a kick later. */
    public function test_a_shootout_ends_the_moment_it_is_decided(): void
    {
        $seen = 0;
        foreach (range(1, 120) as $seed) {
            $s = $this->state($seed);
            $s['competition'] = 'cup';
            [, $ticks] = Runner::toEnd($s);
            $kicks = null;
            foreach ($ticks as $out) {
                foreach ($out['events'] as $e) {
                    $kicks = $e['type'] === 'shootout' ? $e['kicks'] : $kicks;
                }
            }
            if ($kicks === null) {
                continue;
            }
            $seen++;
            $score = ['home' => 0, 'away' => 0];
            $taken = ['home' => 0, 'away' => 0];
            foreach ($kicks as $i => $k) {
                $this->assertSame($i % 2 === 0 ? 'home' : 'away', $k['team'], "seed $seed: home kicks first, then in turn");
                $score[$k['team']] += $k['scored'] ? 1 : 0;
                $taken[$k['team']]++;
                $decided = max($taken) <= 5
                    ? $score['away'] > $score['home'] + 5 - $taken['home'] || $score['home'] > $score['away'] + 5 - $taken['away']
                    : $taken['home'] === $taken['away'] && $score['home'] !== $score['away'];
                $decided = $decided || ($taken['home'] === 5 && $taken['away'] === 5 && $score['home'] !== $score['away']);
                $this->assertSame($i === count($kicks) - 1, $decided, "seed $seed: kick $i");
            }
        }
        $this->assertGreaterThan(0, $seen, 'some draws went to penalties');
    }

    /** [X99] An injured outfield player is replaced by an outfield player; the bench keeper stays for the goal. */
    public function test_an_injured_outfield_player_is_not_replaced_by_the_bench_keeper(): void
    {
        $state = $this->state(3);
        $players = &$state['teams']['home']['players'];
        $bench = array_keys(array_filter($players, fn ($p) => ! $p['on']));
        $keeper = null;
        foreach ($bench as $j) {
            if ($players[$j]['line'] === 'gk') {
                $keeper = $j;
                $players[$j]['a']['ovr'] = 99; // the best on the bench by far
            }
        }
        $this->assertNotNull($keeper);
        $striker = array_key_first(array_filter($players, fn ($p) => $p['on'] && $p['slot_line'] === 'att'));
        unset($players);
        $state['teams']['home']['pending_injury'] = $state['teams']['home']['players'][$striker]['id'];
        $state['teams']['home']['players'][$striker]['on'] = false;
        $state['teams']['home']['players'][$striker]['out'] = 'injury';
        $state['teams']['home']['missing']++;
        $state = Runner::tick($state);
        $team = $state['teams']['home'];
        $this->assertFalse($team['players'][$keeper]['on'], 'the bench keeper stays on the bench');
        $in = array_values(array_filter($team['players'], fn ($p) => $p['on'] && $p['slot'] === $state['teams']['home']['players'][$striker]['slot']));
        $this->assertCount(1, $in);
        $this->assertNotSame('gk', $in[0]['line']);
    }

    /** [Sprint 43 B2] Now and then the finisher's own foul takes the goal away after the VAR: the attackers' foul. */
    public function test_the_attackers_own_foul_takes_a_goal_away_now_and_then(): void
    {
        $seen = 0;
        foreach (range(1, 60) as $seed) {
            [, $ticks] = Runner::toEnd($this->state($seed));
            foreach ($ticks as $out) {
                if (MomentClock::varReason($out['events']) === 'foul') {
                    $seen++;
                    $foul = array_values(array_filter($out['events'], fn ($e) => $e['type'] === 'foul' && ($e['attacking'] ?? false)));
                    $attack = array_values(array_filter($out['events'], fn ($e) => $e['type'] === 'attack'));
                    $this->assertNotEmpty($foul);
                    $this->assertSame($attack[0]['team'], $foul[0]['team'], 'the foul is the attackers\'');
                }
            }
        }
        $this->assertGreaterThan(5, $seen);
        $this->assertLessThan(40, $seen);
    }
}
