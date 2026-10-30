<?php

namespace Tests\Unit;

use App\Characters\Mood;
use PHPUnit\Framework\TestCase;

/** The characters' mood [Sprint 26 B1]: decided on the server from what happened, so every screen only draws it. */
class CharacterMoodTest extends TestCase
{
    private const LEVEL = ['home' => 0, 'away' => 0];

    public function test_a_goal_cheers_its_side_and_saddens_the_other_and_late_it_angers(): void
    {
        $goal = [['type' => 'goal', 'team' => 'home']];
        $this->assertSame(['home' => 'cheer', 'away' => 'sad'], Mood::forTick($goal, ['home' => 1, 'away' => 0], [30, 0]));
        $this->assertSame(['home' => 'cheer', 'away' => 'angry'], Mood::forTick($goal, ['home' => 1, 'away' => 0], [88, 0]));
        // 45+2 counts as 47: not late.
        $this->assertSame('sad', Mood::forTick($goal, ['home' => 1, 'away' => 0], [45, 2])['away']);
    }

    public function test_a_red_card_angers_and_an_injury_worries_only_its_own_side(): void
    {
        $red = [['type' => 'card', 'team' => 'away', 'color' => 'red']];
        $this->assertSame(['home' => 'idle', 'away' => 'angry'], Mood::forTick($red, self::LEVEL, 20));
        $yellow = [['type' => 'card', 'team' => 'away', 'color' => 'yellow']];
        $this->assertSame(['home' => 'idle', 'away' => 'idle'], Mood::forTick($yellow, self::LEVEL, 20));
        $hurt = [['type' => 'injury', 'team' => 'home']];
        $this->assertSame(['home' => 'worried', 'away' => 'idle'], Mood::forTick($hurt, self::LEVEL, 20));
    }

    public function test_a_quiet_minute_worries_the_side_behind_and_calms_the_rest(): void
    {
        $this->assertSame(['home' => 'idle', 'away' => 'worried'], Mood::forTick([], ['home' => 2, 'away' => 1], 60));
        $this->assertSame(['home' => 'idle', 'away' => 'idle'], Mood::forTick([['type' => 'attack', 'team' => 'home']], self::LEVEL, 60));
    }

    public function test_the_final_whistle_is_joy_calm_or_sadness(): void
    {
        $end = [['type' => 'period', 'team' => null, 'name' => 'fulltime']];
        $this->assertSame(['home' => 'sad', 'away' => 'joy'], Mood::forTick($end, ['home' => 0, 'away' => 1], [90, 3]));
        $this->assertSame(['home' => 'idle', 'away' => 'idle'], Mood::forTick($end, ['home' => 2, 'away' => 2], 90));
        // A goal in the last minute and then the whistle: the whistle has the last word.
        $this->assertSame(['home' => 'joy', 'away' => 'sad'], Mood::forTick([['type' => 'goal', 'team' => 'home'], ...$end], ['home' => 1, 'away' => 0], 90));
    }

    public function test_a_match_told_afterwards(): void
    {
        $this->assertSame('joy', Mood::forResult(2, 0, false));
        $this->assertSame('surprise', Mood::forResult(4, 1, false));
        $this->assertSame('idle', Mood::forResult(1, 1, true));
        $this->assertSame('sad', Mood::forResult(0, 1, false));
        $this->assertSame('angry', Mood::forResult(0, 1, true));
    }

    public function test_every_mood_given_is_one_of_the_nine(): void
    {
        $events = [[], [['type' => 'goal', 'team' => 'away']], [['type' => 'card', 'team' => 'home', 'color' => 'red']], [['type' => 'period', 'team' => null, 'name' => 'fulltime']]];
        foreach ($events as $e) {
            foreach (Mood::forTick($e, ['home' => 1, 'away' => 2], 70) as $mood) {
                $this->assertContains($mood, Mood::ALL);
            }
        }
    }
}
