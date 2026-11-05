<?php

namespace Tests\Unit;

use App\League\CupBracket;
use PHPUnit\Framework\TestCase;

/** [Sprint 43 C3] The cup's draw spreads the strongest over every branch, and still draws. Pure. */
class CupSeedingTest extends TestCase
{
    public function test_the_seeding_keeps_the_strongest_apart(): void
    {
        $this->assertSame([0], CupBracket::seeding(1));
        $this->assertSame([0, 2, 3, 1], CupBracket::seeding(4));
        $places = CupBracket::seeding(8);
        // The first two in opposite halves, the first four in four different quarters.
        $this->assertNotSame(intdiv($places[0], 4), intdiv($places[1], 4));
        $this->assertCount(4, array_unique(array_map(fn ($t) => intdiv($t, 2), array_slice($places, 0, 4))));
    }

    public function test_every_branch_gets_its_share_of_the_strong(): void
    {
        $clubs = range(1, 16);   // strongest first
        $firsts = [];
        foreach (range(1, 40) as $seed) {
            $r16 = array_values(array_filter(CupBracket::draw($clubs, $seed), fn ($t) => $t['stage'] === 'r16'));
            $this->assertCount(8, $r16);
            foreach ($r16 as $t) {
                // One of the strongest eight against one of the other eight, in every tie.
                $this->assertTrue(min($t['home'], $t['away']) <= 8 && max($t['home'], $t['away']) > 8, "seed $seed");
            }
            // Each quarter of the bracket (two ties) has one of the strongest four.
            $quarters = [];
            foreach ($r16 as $t) {
                if (min($t['home'], $t['away']) <= 4) {
                    $quarters[] = intdiv($t['slot'] - 1, 2);
                }
            }
            sort($quarters);
            $this->assertSame([0, 1, 2, 3], $quarters, "seed $seed");
            $firsts[] = $r16[0]['away'];
        }
        // Still a draw: the opponents change with the seed.
        $this->assertGreaterThan(3, count(array_unique($firsts)));
    }

    public function test_a_preliminary_round_still_feeds_the_bracket(): void
    {
        $ties = CupBracket::draw(range(1, 20), 7);
        $this->assertCount(4, array_filter($ties, fn ($t) => $t['stage'] === 'preliminary'));
        $r16 = array_values(array_filter($ties, fn ($t) => $t['stage'] === 'r16'));
        $fed = count(array_filter($ties, fn ($t) => $t['stage'] === 'preliminary' && $t['next'] !== null));
        $this->assertSame(4, $fed);
        $this->assertSame(12, count(array_filter(array_merge(array_column($r16, 'home'), array_column($r16, 'away')))));
    }
}
