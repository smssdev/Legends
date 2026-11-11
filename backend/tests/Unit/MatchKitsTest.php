<?php

namespace Tests\Unit;

use App\Data\MatchKits;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

/**
 * [Sprint 57 B1] The match's kits on the server give exactly what the web's rule gave (SimMatch.vue before Sprint 57):
 * the expected kits below were computed by that rule itself on each case.
 */
class MatchKitsTest extends TestCase
{
    /** @return array<string, array{0: array<string, mixed>, 1: array<string, mixed>, 2: array<string, mixed>}> */
    public static function cases(): array
    {
        return [
            'two_reds' => [['primary' => '#EF0107', 'secondary' => '#FFFFFF'], ['primary' => '#C8102E', 'secondary' => '#F6EB61'], ['home' => ['shirt' => '#EF0107', 'trim' => '#FFFFFF', 'shorts' => '#FFFFFF', 'socks' => '#EF0107', 'text' => '#FFFFFF', 'gk' => '#2E8B57', 'pattern' => null], 'away' => ['shirt' => '#F6EB61', 'trim' => '#C8102E', 'shorts' => '#C8102E', 'socks' => '#F6EB61', 'text' => '#0A1F42', 'gk' => '#E9D70B', 'pattern' => null]]],
            'change_kit' => [['primary' => '#EF0107', 'secondary' => '#FFFFFF'], ['primary' => '#C8102E', 'secondary' => '#D00027', 'away_kit' => ['color' => '#1D1D1B', 'pattern' => 'stripes'], 'pattern' => 'hoops'], ['home' => ['shirt' => '#EF0107', 'trim' => '#FFFFFF', 'shorts' => '#FFFFFF', 'socks' => '#EF0107', 'text' => '#FFFFFF', 'gk' => '#2E8B57', 'pattern' => null], 'away' => ['shirt' => '#1D1D1B', 'trim' => '#C8102E', 'shorts' => '#1D1D1B', 'socks' => '#1D1D1B', 'text' => '#FFFFFF', 'gk' => '#E9D70B', 'pattern' => 'stripes']]],
            'white' => [['primary' => '#C8102E', 'secondary' => '#B0101F'], ['primary' => '#D00027', 'secondary' => '#C0001A'], ['home' => ['shirt' => '#C8102E', 'trim' => '#B0101F', 'shorts' => '#C8102E', 'socks' => '#C8102E', 'text' => '#FFFFFF', 'gk' => '#2E8B57', 'pattern' => null], 'away' => ['shirt' => '#F3F0E6', 'trim' => '#D00027', 'shorts' => '#D00027', 'socks' => '#F3F0E6', 'text' => '#0A1F42', 'gk' => '#E9D70B', 'pattern' => null]]],
            'navy' => [['primary' => '#F3F0E6', 'secondary' => '#EEEEEE'], ['primary' => '#FFFFFF', 'secondary' => '#F0F0F0'], ['home' => ['shirt' => '#F3F0E6', 'trim' => '#EEEEEE', 'shorts' => '#F3F0E6', 'socks' => '#F3F0E6', 'text' => '#0A1F42', 'gk' => '#2E8B57', 'pattern' => null], 'away' => ['shirt' => '#1C2333', 'trim' => '#FFFFFF', 'shorts' => '#FFFFFF', 'socks' => '#1C2333', 'text' => '#FFFFFF', 'gk' => '#E9D70B', 'pattern' => null]]],
            'apart' => [['primary' => '#FFFFFF', 'secondary' => '#00529F', 'pattern' => 'sash'], ['primary' => '#A50044', 'secondary' => '#004D98', 'pattern' => 'stripes'], ['home' => ['shirt' => '#FFFFFF', 'trim' => '#00529F', 'shorts' => '#00529F', 'socks' => '#FFFFFF', 'text' => '#0A1F42', 'gk' => '#2E8B57', 'pattern' => 'sash'], 'away' => ['shirt' => '#A50044', 'trim' => '#004D98', 'shorts' => '#A50044', 'socks' => '#A50044', 'text' => '#FFFFFF', 'gk' => '#E9D70B', 'pattern' => 'stripes']]],
        ];
    }

    #[DataProvider('cases')]
    public function test_the_kits_are_the_webs_rule(array $home, array $away, array $expected): void
    {
        $this->assertSame($expected, MatchKits::of($home, $away));
    }

    public function test_a_club_with_only_its_data_colour_names_works_too(): void
    {
        $k = MatchKits::of(['color_primary' => '#FFFFFF', 'color_secondary' => '#00529F'], ['color_primary' => '#A50044', 'color_secondary' => '#004D98']);
        $this->assertSame('#FFFFFF', $k['home']['shirt']);
        $this->assertSame('#A50044', $k['away']['shirt']);
    }
}
