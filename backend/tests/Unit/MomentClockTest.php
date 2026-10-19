<?php

namespace Tests\Unit;

use App\Simulator\MomentClock;
use PHPUnit\Framework\TestCase;

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
}
