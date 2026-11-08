<?php

namespace Tests\Unit;

use App\Engine\AutoPick;
use App\Engine\Formations;
use PHPUnit\Framework\TestCase;

/** [Sprint 48 B1] The auto-pick keeps the keeper in goal however far the field players outrate him. */
class AutoPickKeeperTest extends TestCase
{
    public function test_a_weak_keeper_still_keeps_goal_against_a_squad_of_stars(): void
    {
        $lines = ['GK' => 'gk', 'CB' => 'def', 'RB' => 'def', 'LB' => 'def', 'CM' => 'mid', 'CDM' => 'mid', 'ST' => 'att', 'LW' => 'att', 'RW' => 'att'];
        $positions = ['CB', 'CB', 'CB', 'RB', 'LB', 'CM', 'CM', 'CDM', 'CM', 'ST', 'ST', 'LW', 'RW', 'ST', 'CM'];
        $squad = array_map(fn ($pos, $i) => ['id' => 10 + $i, 'pos' => $pos, 'alt' => '', 'line' => $lines[$pos], 'a' => ['ovr' => 99]], $positions, array_keys($positions));
        $squad[] = ['id' => 1, 'pos' => 'GK', 'alt' => '', 'line' => 'gk', 'a' => ['ovr' => 38]];

        $pick = AutoPick::pick($squad);
        $slots = Formations::slots($pick['formation']);
        foreach ($pick['starters'] as $i => $id) {
            if ($slots[$i]['line'] === 'gk') {
                $this->assertSame(1, $id, 'the keeper is in goal');
            }
        }
        $this->assertContains(1, $pick['starters']);
    }
}
