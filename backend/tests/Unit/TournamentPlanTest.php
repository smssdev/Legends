<?php

namespace Tests\Unit;

use App\Tournament\TournamentPlan;
use App\Tournament\TournamentStage;
use PHPUnit\Framework\TestCase;

/** [Sprint 29] A tournament's shape from its draw: pots, groups, rounds and the knockout after them. Pure. */
class TournamentPlanTest extends TestCase
{
    public function test_groups_are_drawn_from_pots_and_each_group_gets_one_of_each_pot(): void
    {
        $teams = range(1, 32);
        $plan = TournamentPlan::make($teams, 7, 'groups', 8, 2, 1);
        $this->assertCount(32, $plan['steps']);
        $this->assertCount(32, $plan['groups']);
        // Pot 1 is the strongest eight, one in each group.
        $pot1 = array_filter($plan['steps'], fn ($s) => $s['pot'] === 1);
        $this->assertEqualsCanonicalizing(range(1, 8), array_column($pot1, 'club'));
        $this->assertEqualsCanonicalizing(range(1, 8), array_column($pot1, 'group'));
        foreach (array_count_values($plan['groups']) as $size) {
            $this->assertSame(4, $size);
        }
        // Three rounds of single matches in groups of four: 16 matches a round.
        $this->assertCount(3, $plan['rounds']);
        $this->assertCount(16, $plan['rounds'][0]['matches']);
        // The same seed, the same draw; another seed, another.
        $this->assertSame($plan, TournamentPlan::make($teams, 7, 'groups', 8, 2, 1));
        $this->assertNotSame($plan['groups'], TournamentPlan::make($teams, 8, 'groups', 8, 2, 1)['groups']);
    }

    public function test_every_team_meets_every_team_of_its_group_once_or_twice(): void
    {
        foreach ([1, 2] as $legs) {
            $plan = TournamentPlan::make(range(1, 10), 3, 'groups', 2, 2, $legs);
            $met = [];
            foreach ($plan['rounds'] as $round) {
                foreach ($round['matches'] as [$h, $a]) {
                    $this->assertSame($plan['groups'][$h], $plan['groups'][$a]);
                    $key = min($h, $a).'-'.max($h, $a);
                    $met[$key] = ($met[$key] ?? 0) + 1;
                }
            }
            // Two groups of five: 10 pairs each.
            $this->assertCount(20, $met);
            $this->assertSame([$legs], array_values(array_unique($met)));
        }
    }

    public function test_the_knockout_after_groups_keeps_a_group_apart_until_the_final(): void
    {
        $ties = TournamentPlan::afterGroups(4, 2);
        $qf = array_values(array_filter($ties, fn ($t) => $t['stage'] === 'qf'));
        $this->assertSame([['A1', 'B2'], ['C1', 'D2'], ['B1', 'A2'], ['D1', 'C2']], array_map(fn ($t) => [$t['home_from'], $t['away_from']], $qf));
        $this->assertSame(['qf', 'sf', 'final'], TournamentPlan::stages($ties));
        // A1 and A2 are in opposite halves: quarter-finals 1-2 feed semi-final 1, 3-4 semi-final 2.
        $this->assertSame(['sf', 1, 'home'], $qf[0]['next']);
        $this->assertSame(['sf', 2, 'home'], $qf[2]['next']);
        // One group of four, two through: a final.
        $this->assertSame([['A1', 'A2']], array_map(fn ($t) => [$t['home_from'], $t['away_from']], TournamentPlan::afterGroups(1, 2)));
        // Winners only from eight groups: a round of eight.
        $this->assertSame('qf', TournamentPlan::afterGroups(8, 1)[0]['stage']);
    }

    public function test_a_league_of_two_and_a_knockout_of_three(): void
    {
        $two = TournamentPlan::make([5, 9], 1, 'league', 1, 2, 2);
        $this->assertCount(2, $two['rounds']);
        $this->assertCount(2, $two['steps']);
        $three = TournamentPlan::make([1, 2, 3], 1, 'knockout');
        $this->assertSame(['preliminary', 'final'], TournamentPlan::stages($three['ties']));
        $this->assertCount(3, $three['steps']);
    }

    /** [Sprint 43 A3] The World Cup of 48: the first two of 12 groups and the 8 best thirds to a round of 32. */
    public function test_twelve_groups_and_the_best_thirds_make_a_round_of_32(): void
    {
        $ties = TournamentPlan::afterGroups(12, 2, 8);
        $first = array_values(array_filter($ties, fn ($t) => $t['stage'] === 'r32'));
        $this->assertCount(16, $first);
        $this->assertSame(['r32', 'r16', 'qf', 'sf', 'final'], TournamentPlan::stages($ties));
        $sides = array_merge(array_column($first, 'home_from'), array_column($first, 'away_from'));
        sort($sides);
        $expected = [];
        foreach (range('A', 'L') as $g) {
            $expected[] = $g.'1';
            $expected[] = $g.'2';
        }
        foreach (range(1, 8) as $k) {
            $expected[] = '3:'.$k;
        }
        sort($expected);
        $this->assertSame($expected, $sides, 'every winner, runner-up and best third once');
        foreach ($first as $t) {
            $this->assertNotSame($t['home_from'][0], $t['away_from'][0], 'never two of one group');
        }
    }

    /** [Sprint 43 A3] The best thirds by points, then each in a place whose winner is of another group. */
    public function test_the_best_thirds_never_meet_their_own_groups_winner(): void
    {
        $row = fn (int $id, int $pts, int $gd = 0) => ['id' => $id, 'pts' => $pts, 'gd' => $gd, 'gf' => 0, 'st' => 0];
        $tables = [];
        foreach (range(1, 12) as $g) {
            // Group g's third: id 300 + g, the earlier groups' thirds better.
            $tables[$g] = [$row(100 + $g, 9), $row(200 + $g, 6), $row(300 + $g, 13 - $g), $row(400 + $g, 0)];
        }
        $thirds = TournamentStage::thirds($tables, 8);
        $this->assertCount(8, $thirds);
        $this->assertEqualsCanonicalizing(range(301, 308), array_values($thirds), 'the eight best: groups A to H');
        foreach ($thirds as $k => $club) {
            $this->assertNotSame(300 + $k, $club, "place 3:$k faces the winner of group $k");
        }
        $this->assertSame([], TournamentStage::thirds($tables, 0));
    }
}
