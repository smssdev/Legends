<?php

namespace Tests\Unit;

use App\Characters\Mood;
use App\Engine\MatchSetup;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use App\Simulator\Voice;
use Tests\TestCase;

class MomentClockTest extends TestCase
{
    private array $match = ['tick_ms' => 3000, 'moment_ms' => [
        'quiet' => 900, 'attack' => 1600, 'stoppage' => 2400, 'shootout' => 3000, 'offside' => 6400, 'miss' => 7000, 'save' => 6400,
        'corner' => 5600, 'goal' => 12800, 'yellow' => 6800, 'red' => 9000, 'free_kick' => 8600, 'free_kick_goal' => 9400,
        'penalty' => 10000, 'penalty_goal' => 10600, 'sub' => 5600, 'injury' => 6000,
    ]];

    public function test_each_minute_gets_the_shot_of_its_most_important_event(): void
    {
        $attack = fn ($result) => ['type' => 'attack', 'team' => 'home', 'result' => $result];
        $cases = [
            'quiet' => [],
            'attack' => [$attack('lost')],
            'miss' => [$attack('blocked')],
            'save' => [$attack('saved')],
            'offside' => [$attack('offside')],
            'goal' => [['type' => 'goal', 'team' => 'home', 'kind' => 'open'], $attack('goal'), ['type' => 'sub', 'team' => 'away']],
            'penalty' => [$attack('penalty'), ['type' => 'penalty', 'team' => 'home', 'scored' => false]],
            'red' => [$attack('foul'), ['type' => 'foul', 'team' => 'away'], ['type' => 'card', 'team' => 'away', 'color' => 'red']],
            'corner' => [['type' => 'corner', 'team' => 'home']],
            'sub' => [['type' => 'sub', 'team' => 'home']],
            'stoppage' => [['type' => 'stoppage', 'added' => 3]],
            'coach' => [['type' => 'action', 'team' => 'home', 'action' => ['type' => 'tactics', 'tactics' => ['pressing' => 80]]], $attack('lost')],
            'whistle' => [['type' => 'period', 'team' => null, 'name' => 'halftime']],
        ];
        foreach ($cases as $kind => $events) {
            $this->assertSame($kind, MomentClock::kind($events), $kind);
        }
    }

    public function test_durations_come_from_the_config_and_scored_set_pieces_play_longer(): void
    {
        $this->assertSame(['kind' => 'quiet', 'ms' => 900], MomentClock::moment([], $this->match));
        // A sub ordered by the coach plays the sub shot, not the coach's.
        $this->assertSame('sub', MomentClock::kind([['type' => 'action', 'team' => 'home', 'action' => ['type' => 'sub']], ['type' => 'sub', 'team' => 'home']]));
        $pen = [['type' => 'penalty', 'team' => 'home', 'scored' => true], ['type' => 'goal', 'team' => 'home', 'kind' => 'penalty']];
        $this->assertSame(['kind' => 'penalty', 'ms' => 10600], MomentClock::moment($pen, $this->match));
        // The pause after a scene is added to it, not to the quiet minutes.
        $paused = $this->match + ['scene_gap_ms' => 1500];
        $this->assertSame(10600 + 1500, MomentClock::moment($pen, $paused)['ms']);
        $this->assertSame(900, MomentClock::moment([], $paused)['ms']);
        // Matches created before the table existed keep the fixed minute.
        $this->assertSame(3000, MomentClock::moment([], ['tick_ms' => 3000])['ms']);
    }

    /** [X35] The broadcast's pace: 18 minutes of football a real minute, extra time and the shootout half a minute. */
    public function test_the_broadcast_plays_every_minute_at_a_fixed_pace(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000];
        $goal = [['type' => 'goal', 'team' => 'home', 'kind' => 'open']];
        $this->assertSame(['kind' => 'quiet', 'ms' => 3333], MomentClock::moment([], $match, 1));
        $this->assertSame(['kind' => 'goal', 'ms' => 3333], MomentClock::moment($goal, $match, 2));
        // A half of 45 minutes is two and a half real minutes; an extra-time half (15) half a minute.
        $this->assertSame(150, intdiv(45 * MomentClock::moment([], $match, 1)['ms'] + 999, 1000));
        $this->assertSame(30000, 15 * MomentClock::moment($goal, $match, 3)['ms']);
        $this->assertSame(30000, MomentClock::moment([['type' => 'shootout', 'team' => null]], $match, 5)['ms']);
    }

    /** [X41] The broadcast as on TV: a small chance is only its card, a big moment its real length. */
    public function test_the_broadcast_gives_the_big_moments_their_length_and_the_small_ones_a_card(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000, 'broadcast_ms' => config('game.match.broadcast_ms')];
        $shot = fn (string $result, string $quality) => [['type' => 'attack', 'team' => 'home', 'result' => $result, 'quality' => $quality]];
        $this->assertSame(['kind' => 'goal', 'ms' => 20000], MomentClock::moment([['type' => 'goal', 'team' => 'home', 'kind' => 'open']], $match));
        $this->assertSame(['kind' => 'miss', 'ms' => 10000], MomentClock::moment($shot('missed', 'big'), $match));
        $this->assertSame(['kind' => 'save', 'ms' => 11000], MomentClock::moment($shot('saved', 'header'), $match));
        foreach ([$shot('blocked', 'big'), $shot('missed', 'long'), $shot('saved', 'normal'), $shot('offside', '')] as $events) {
            $this->assertTrue(MomentClock::moment($events, $match)['brief'] ?? false);
        }
        $this->assertTrue(MomentClock::moment([['type' => 'free_kick', 'team' => 'home', 'taker' => 1]], $match)['brief'] ?? false);
        $this->assertArrayNotHasKey('brief', MomentClock::moment([['type' => 'free_kick', 'team' => 'home', 'taker' => 1, 'keeper' => 2]], $match));
        $this->assertSame(30000, MomentClock::moment([['type' => 'shootout', 'team' => null]], $match, 5)['ms']);
    }

    /** [X41] The owner's length: a half about three and a half real minutes. */
    public function test_a_broadcast_half_lasts_about_three_and_a_half_minutes(): void
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        $squad = fn (int $base, int $ovr) => array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P{$base}x{$i}", 'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
            'overall' => $ovr - intdiv($i, 3), 'penalties' => 70, 'free_kick' => 65, 'crossing' => 65, 'heading' => 65,
        ], $positions, array_keys($positions));
        $club = fn ($id) => ['id' => $id, 'name' => "C{$id}", 'code' => 'C'.$id, 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];
        $ms = 0;
        $halves = 0;
        foreach ([3, 11, 42, 77] as $seed) {
            $state = MatchSetup::build(['club' => $club(1), 'squad' => $squad(100, 80)], ['club' => $club(2), 'squad' => $squad(200, 78)],
                ['seed' => $seed, 'competition' => 'league'], ['match' => config('game.match'), 'engine' => config('game.engine')]);
            while (! $state['finished']) {
                $state = Runner::tick($state);
                $ms += MomentClock::moment($state['out']['events'], $state['cfg']['match'], (int) ($state['out']['period'] ?? 1))['ms'];
            }
            $halves += 2;
        }
        $half = intdiv($ms, $halves);
        $this->assertGreaterThan(165000, $half);
        $this->assertLessThan(255000, $half);
    }

    /** [Sprint 35 C3] A goal ruled out by VAR: a big chance offside, or one the attackers fouled in; with its reason. */
    public function test_a_goal_ruled_out_by_var(): void
    {
        $attack = fn ($result, $quality = 'big', $receiver = 1) => ['type' => 'attack', 'team' => 'home', 'result' => $result, 'quality' => $quality, 'carrier' => 5, 'receiver' => $receiver, 'lane' => 'center'];
        // One offside in three (by the attack's own players), the same every time.
        $kinds = array_map(fn ($r) => MomentClock::kind([$attack('offside', null, $r)]), range(1, 30));
        $vars = count(array_filter($kinds, fn ($k) => $k === 'var'));
        $this->assertGreaterThan(4, $vars);
        $this->assertLessThan(20, $vars);
        $this->assertSame($kinds, array_map(fn ($r) => MomentClock::kind([$attack('offside', null, $r)]), range(1, 30)));
        $r = array_search('var', $kinds, true) + 1;
        $this->assertSame('offside', MomentClock::varReason([$attack('offside', null, $r)]));
        $foul = [$attack('missed'), ['type' => 'foul', 'team' => 'home', 'penalty' => false]];
        $this->assertSame('var', MomentClock::kind($foul));
        $this->assertSame('foul', MomentClock::varReason($foul));
        $this->assertSame('miss', MomentClock::kind([$attack('missed'), ['type' => 'foul', 'team' => 'away']]), 'the defenders\' foul rules nothing out');
        // A card still has its own scene.
        $this->assertSame('yellow', MomentClock::kind([...$foul, ['type' => 'card', 'team' => 'home', 'color' => 'yellow']]));
        $m = MomentClock::moment($foul, config('game.match'));
        $this->assertSame(['kind' => 'var', 'ms' => (int) config('game.match.broadcast_ms.var'), 'var' => 'foul'], $m);
        $voice = Voice::for($foul, 'var', 3, 10);
        $this->assertSame('var_foul', $voice['line']);
        $moods = Mood::forTick([$attack('offside', null, $r)], ['home' => 0, 'away' => 0], 30);
        $this->assertSame(['home' => 'angry', 'away' => 'joy'], $moods);
    }
}
