<?php

namespace Tests\Unit;

use App\League\LeagueFactory;
use Tests\TestCase;

/** League rounds and the last quarter, for every team count a league can have [PLAN 2.1, 2.4]. */
class LeagueRoundsTest extends TestCase
{
    public function test_rounds_and_the_first_locked_round_for_4_to_20_teams(): void
    {
        $this->assertSame([6, 5], [LeagueFactory::rounds(4), LeagueFactory::lockFromRound(6)]);
        $this->assertSame([10, 8], [LeagueFactory::rounds(5), LeagueFactory::lockFromRound(10)]);
        $this->assertSame([38, 29], [LeagueFactory::rounds(20), LeagueFactory::lockFromRound(38)]);
        foreach (range(4, 20) as $teams) {
            $rounds = LeagueFactory::rounds($teams);
            $locked = $rounds - LeagueFactory::lockFromRound($rounds) + 1;
            // Every team plays every other twice; with an odd count each also rests twice.
            $this->assertSame(2 * ($teams - 1) + ($teams % 2) * 2, $rounds);
            // The locked rounds are a quarter, never less.
            $this->assertGreaterThanOrEqual($rounds / 4, $locked);
            $this->assertLessThan($rounds / 4 + 1, $locked);
        }
    }
}
