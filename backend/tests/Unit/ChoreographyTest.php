<?php

namespace Tests\Unit;

use App\Engine\MatchSetup;
use App\Simulator\MatchChoreographer;
use App\Simulator\Runner;
use Tests\TestCase;

/** [Sprint 32 R1 to R4] The players' movement the server draws: passes to a player, runs, marking, busy minutes. */
class ChoreographyTest extends TestCase
{
    private function state(int $seed): array
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        $squad = fn (int $base) => array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P{$base}x{$i}", 'position' => $pos, 'line' => $lines[$pos], 'age' => 24,
            'overall' => 80 - intdiv($i, 3), 'pac' => 70, 'sho' => 65, 'pas' => 70, 'dri' => 70, 'def' => 65, 'phy' => 70,
        ], $positions, array_keys($positions));
        $club = fn ($id) => ['id' => $id, 'name' => "C{$id}", 'code' => "C{$id}", 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];

        return MatchSetup::build(['club' => $club(1), 'squad' => $squad(100)], ['club' => $club(2), 'squad' => $squad(200)],
            ['seed' => $seed], ['match' => config('game.match'), 'engine' => config('game.engine')]);
    }

    /** Every minute of a match with its Keyframes. */
    private function minutes(int $seed): array
    {
        $state = $this->state($seed);
        $ball = [525, 340];
        $all = [];
        while (! $state['finished']) {
            $state = Runner::tick($state);
            $c = MatchChoreographer::frames($state, $state['out'], $ball);
            $ball = $c['ball'];
            $all[] = [$state['out'], $c['frames']];
        }

        return $all;
    }

    public function test_a_busy_minute_has_ten_keyframes_and_a_quiet_one_six(): void
    {
        $busy = $quiet = 0;
        foreach ($this->minutes(11) as [$out, $frames]) {
            $chance = collect($out['events'])->contains(fn ($e) => in_array($e['type'], ['corner', 'goal', 'free_kick', 'penalty'], true)
                || ($e['type'] === 'attack' && in_array($e['result'] ?? null, ['goal', 'saved', 'missed', 'blocked'], true)));
            $this->assertCount($chance ? 10 : 6, $frames, 'tick '.$out['tick']);
            $chance ? $busy++ : $quiet++;
            foreach ($frames as $f) {
                foreach ([...$f['b'], ...array_merge(...array_values($f['p']))] as $v) {
                    $this->assertIsInt($v);
                }
                $this->assertArrayNotHasKey('sides', $f);
            }
        }
        $this->assertGreaterThan(0, $busy);
        $this->assertGreaterThan(0, $quiet);
    }

    public function test_the_next_holder_runs_towards_the_ball_before_it_reaches_him(): void
    {
        $runs = 0;
        foreach ($this->minutes(23) as [, $frames]) {
            for ($i = 0; $i < count($frames) - 1; $i++) {
                $next = $frames[$i + 1]['h'];
                if ($next === null || $next === $frames[$i]['h'] || ! isset($frames[$i]['p'][$next])) {
                    continue;
                }
                $runs++;
                // Halfway: he is no farther from where he takes the ball than the step he still has to make.
                [$x, $y] = $frames[$i]['p'][$next];
                [$tx, $ty] = $frames[$i + 1]['p'][$next];
                $this->assertLessThanOrEqual(400, abs($tx - $x) + abs($ty - $y));
            }
        }
        $this->assertGreaterThan(20, $runs);
    }

    public function test_the_side_without_the_ball_closes_on_its_opponents(): void
    {
        $closer = $farther = 0;
        foreach ($this->minutes(5) as [$out, $frames]) {
            foreach ($frames as $f) {
                if ($f['h'] === null) {
                    continue;
                }
                $mine = $f['h'] < 200 ? 'h' : 'a';
                $att = array_filter($f['p'], fn ($id) => ($id < 200) === ($mine === 'h'), ARRAY_FILTER_USE_KEY);
                $def = array_filter($f['p'], fn ($id) => ($id < 200) !== ($mine === 'h') && $id % 100 !== 0, ARRAY_FILTER_USE_KEY);
                $gap = 0;
                foreach ($def as [$x, $y]) {
                    $gap += min(array_map(fn ($a) => abs($a[0] - $x) + abs($a[1] - $y), $att));
                }
                $gap / max(1, count($def)) < 140 ? $closer++ : $farther++;
            }
        }
        // Defenders are near an opponent most of the time.
        $this->assertGreaterThan($farther, $closer);
    }

    /** [Sprint 33 B1] A pass in flight belongs to no one, and the ball is carried before it is passed. */
    public function test_a_pass_in_flight_has_no_holder_and_the_ball_is_carried_before(): void
    {
        $flying = $carried = 0;
        foreach ($this->minutes(17) as [, $frames]) {
            foreach ($frames as $f) {
                $f['h'] === null ? $flying++ : $carried++;
            }
        }
        $this->assertGreaterThan(50, $flying);
        $this->assertGreaterThan(50, $carried);
    }

    /** [Sprint 33 B2, B3] Set pieces, the kick-off and the back line. */
    public function test_set_pieces_the_kick_off_and_the_back_line(): void
    {
        $state = $this->state(3);
        $state['out'] = ['tick' => 30, 'events' => [['type' => 'penalty', 'team' => 'home', 'scored' => true]]];
        $frames = MatchChoreographer::frames($state, $state['out'], [700, 340])['frames'];
        $this->assertCount(10, $frames);
        // At the spot: everyone but the taker and the keepers outside the box (the home side attacks x = 1050).
        $atSpot = collect($frames)->sortBy(fn ($f) => abs($f['b'][0] - 940) + abs($f['b'][1] - 340))->first();
        $this->assertLessThan(60, abs($atSpot['b'][0] - 940) + abs($atSpot['b'][1] - 340), 'a Keyframe at the spot');
        foreach ($atSpot['p'] as $id => [$x, $y]) {
            if ($id !== $atSpot['h'] && $id % 100 !== 0) {
                $this->assertLessThan(885, $x, "player {$id} outside the box");
            }
        }

        $state['out'] = ['tick' => 31, 'events' => [['type' => 'goal', 'team' => 'home']]];
        $frames = MatchChoreographer::frames($state, $state['out'], [1048, 340])['frames'];
        $last = end($frames);
        $this->assertSame([525, 340, 0], $last['b']);
        foreach ($last['p'] as $id => [$x]) {
            $id < 200 ? $this->assertLessThanOrEqual(510, $x, "home {$id} in its half") : $this->assertGreaterThanOrEqual(540, $x, "away {$id} in its half");
        }

        // The back line: the defenders of the side without the ball level with one another.
        $levels = 0;
        foreach ($this->minutes(9) as [, $frames]) {
            foreach ($frames as $f) {
                if ($f['h'] === null) {
                    continue;
                }
                $def = $f['h'] < 200 ? [202, 203, 204, 205] : [102, 103, 104, 105];
                $xs = array_unique(array_map(fn ($id) => $f['p'][$id][0] ?? -1, $def));
                $levels += count($xs) === 1 ? 1 : 0;
            }
        }
        $this->assertGreaterThan(20, $levels);
    }

    /** [Sprint 33 B4] The players the commentary names have the ball on the pitch: the shooter is seen shooting when he is near. */
    public function test_the_named_shooter_has_the_ball(): void
    {
        $shots = $seen = 0;
        foreach ([4, 8, 15] as $seed) {
            foreach ($this->minutes($seed) as [$out, $frames]) {
                foreach ($out['events'] as $e) {
                    if ($e['type'] === 'attack' && isset($e['shooter']) && in_array('shot', array_column($e['phases'], 'n'), true)) {
                        $shots++;
                        $seen += in_array($e['shooter'], array_column($frames, 'h'), true) ? 1 : 0;
                    }
                }
            }
        }
        $this->assertGreaterThan(5, $shots);
        // Only when he is close enough to reach it without a jump (25 m): about a third of the time.
        $this->assertGreaterThan($shots / 4, $seen, "{$seen} of {$shots} shooters on the ball");
    }
}
