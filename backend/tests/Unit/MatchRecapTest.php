<?php

namespace Tests\Unit;

use App\League\MatchRecap;
use PHPUnit\Framework\TestCase;

/** [Sprint 24 B1] The quick recap: the big moments in order with the score after each, then the numbers. */
class MatchRecapTest extends TestCase
{
    private const REPORT = [
        'side' => 'home', 'result' => 'win', 'score' => ['home' => 2, 'away' => 1], 'shootout' => null,
        'timeline' => [
            ['minute' => 12, 'type' => 'goal', 'team' => 'home', 'scorer' => 7, 'assist' => 9, 'score' => ['home' => 1, 'away' => 0]],
            ['minute' => 30, 'type' => 'card', 'team' => 'away', 'player' => 21, 'color' => 'yellow'],
            ['minute' => 44, 'type' => 'foul', 'team' => 'away', 'player' => 21],
            ['minute' => 55, 'type' => 'goal', 'team' => 'away', 'scorer' => 22, 'assist' => 0],
            ['minute' => 60, 'type' => 'sub', 'team' => 'home', 'out' => 9, 'in' => 12],
            ['minute' => 81, 'type' => 'goal', 'team' => 'home', 'scorer' => 12, 'assist' => 0, 'score' => ['home' => 2, 'away' => 1]],
        ],
        'ratings' => [
            'home' => [['id' => 7, 'name' => 'Salah', 'rating' => 840], ['id' => 12, 'name' => 'Jota', 'rating' => 760], ['id' => 9, 'name' => 'Nunez', 'rating' => 650], ['id' => 3, 'name' => 'Robertson', 'rating' => 640]],
            'away' => [['id' => 22, 'name' => 'Saka', 'rating' => 720], ['id' => 21, 'name' => 'Rice', 'rating' => 610]],
        ],
        'stats' => ['home' => ['attacks' => 60, 'shots' => 14, 'on_target' => 6, 'yellow' => 0], 'away' => ['attacks' => 40, 'shots' => 8, 'on_target' => 3, 'yellow' => 1]],
        'man_of_the_match' => ['id' => 7, 'name' => 'Salah', 'team' => 'home', 'rating' => 840],
    ];

    public function test_the_moments_in_order_with_the_score_as_it_moved(): void
    {
        $recap = MatchRecap::build(self::REPORT);
        // The foul is not a big moment.
        $this->assertSame(['goal', 'card', 'goal', 'sub', 'goal'], array_column($recap['moments'], 'type'));
        $this->assertSame([[1, 0], [1, 0], [1, 1], [1, 1], [2, 1]], array_map(fn ($m) => [$m['score']['home'], $m['score']['away']], $recap['moments']));
        $this->assertSame(['Salah', 'Nunez'], [$recap['moments'][0]['player'], $recap['moments'][0]['other']]);
        $this->assertSame(['Rice', 'yellow'], [$recap['moments'][1]['player'], $recap['moments'][1]['color']]);
        // A substitution: who went off, and who came on.
        $this->assertSame(['Nunez', 'Jota'], [$recap['moments'][3]['player'], $recap['moments'][3]['other']]);
        $this->assertNull($recap['moments'][2]['other']);
    }

    public function test_the_numbers_and_the_best_of_each_side(): void
    {
        $recap = MatchRecap::build(self::REPORT);
        $this->assertSame([60, 40], [$recap['stats']['home']['possession'], $recap['stats']['away']['possession']]);
        $this->assertSame([14, 6, 1], [$recap['stats']['home']['shots'], $recap['stats']['home']['on_target'], $recap['stats']['away']['yellow']]);
        $this->assertSame(0, $recap['stats']['home']['corners']);
        $this->assertSame(['Salah', 'Jota', 'Nunez'], array_column($recap['best']['home'], 'name'));
        $this->assertCount(2, $recap['best']['away']);
        $this->assertSame(['home' => 2, 'away' => 1], $recap['score']);
        $this->assertSame('home', $recap['side']);
    }

    public function test_a_match_without_attacks_is_even_and_without_moments_goes_to_the_end(): void
    {
        $recap = MatchRecap::build(['result' => 'draw', 'score' => ['home' => 0, 'away' => 0], 'timeline' => [], 'ratings' => [], 'stats' => []]);
        $this->assertSame([], $recap['moments']);
        $this->assertSame([50, 50], [$recap['stats']['home']['possession'], $recap['stats']['away']['possession']]);
        // Thirds that do not divide evenly still make 100.
        $odd = MatchRecap::build(['result' => 'draw', 'score' => ['home' => 0, 'away' => 0], 'timeline' => [], 'stats' => ['home' => ['attacks' => 1], 'away' => ['attacks' => 2]]]);
        $this->assertSame(100, $odd['stats']['home']['possession'] + $odd['stats']['away']['possession']);
    }
}
