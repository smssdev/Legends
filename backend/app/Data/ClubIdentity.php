<?php

namespace App\Data;

/**
 * A short code and two colors for each club, used for the generated crest
 * (no real logos, docs/PLAN.md 2.6). Known clubs get their real colors; the
 * rest get a stable pair picked from the club name.
 */
class ClubIdentity
{
    private const KNOWN = [
        'Liverpool' => ['LIV', '#C8102E', '#F6C343'],
        'Arsenal' => ['ARS', '#DB0007', '#FFFFFF'],
        'Manchester City' => ['MCI', '#6CABDD', '#FFFFFF'],
        'Man Utd' => ['MUN', '#DA291C', '#FBE122'],
        'Chelsea' => ['CHE', '#034694', '#DBA111'],
        'Spurs' => ['TOT', '#132257', '#FFFFFF'],
        'Newcastle Utd' => ['NEW', '#241F20', '#FFFFFF'],
        'Aston Villa' => ['AVL', '#670E36', '#95BFE5'],
        'Real Madrid' => ['RMA', '#FFFFFF', '#FEBE10'],
        'FC Barcelona' => ['BAR', '#A50044', '#004D98'],
        'Atlético de Madrid' => ['ATM', '#CB3524', '#272E61'],
        'FC Bayern München' => ['FCB', '#DC052D', '#FFFFFF'],
        'Borussia Dortmund' => ['BVB', '#FDE100', '#000000'],
        'Paris SG' => ['PSG', '#004170', '#DA291C'],
        'Juventus' => ['JUV', '#000000', '#FFFFFF'],
        'Lombardia FC' => ['INT', '#0068A8', '#000000'],
        'Milano FC' => ['MIL', '#FB090B', '#000000'],
        'SSC Napoli' => ['NAP', '#12A0D7', '#FFFFFF'],
        'Al Hilal' => ['HIL', '#0B4EA2', '#FFFFFF'],
        'Al Nassr' => ['NAS', '#FCE300', '#1A3D8F'],
        'Al Ittihad' => ['ITT', '#FDD20A', '#000000'],
        'Al Ahli' => ['AHL', '#00843D', '#FFFFFF'],
    ];

    private const PALETTE = [
        ['#C8102E', '#FFFFFF'], ['#034694', '#FFFFFF'], ['#00843D', '#FFFFFF'], ['#FDE100', '#1A1A1A'],
        ['#1A1A1A', '#FFFFFF'], ['#6CABDD', '#0A1F42'], ['#7A263A', '#F3D459'], ['#F18A01', '#1A1A1A'],
        ['#5C2D91', '#FFFFFF'], ['#FFFFFF', '#C8102E'], ['#0B4EA2', '#FCE300'], ['#008080', '#FFFFFF'],
    ];

    public static function code(string $name): string
    {
        if (isset(self::KNOWN[$name])) {
            return self::KNOWN[$name][0];
        }

        $ascii = preg_replace('/[^A-Za-z ]/', '', (string) iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $name));
        $words = preg_split('/\s+/', $ascii, -1, PREG_SPLIT_NO_EMPTY);
        $words = array_values(array_filter($words, fn ($w) => ! in_array(strtoupper($w), ['FC', 'CF', 'AC', 'SC', 'CD', 'AFC', 'SV', 'FK', 'AS', 'RC', 'CA', 'UD', 'SD'], true)));
        $letters = count($words) >= 3
            ? $words[0][0].$words[1][0].$words[2][0]
            : substr(implode('', $words) ?: 'CLB', 0, 3);

        return strtoupper(str_pad($letters, 3, 'X'));
    }

    /** @return array{0: string, 1: string} */
    public static function colors(string $name): array
    {
        if (isset(self::KNOWN[$name])) {
            return [self::KNOWN[$name][1], self::KNOWN[$name][2]];
        }

        return self::PALETTE[crc32($name) % count(self::PALETTE)];
    }
}
