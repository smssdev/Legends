<?php

namespace App\Data;

/**
 * [Sprint 57 B1] Both sides' final kits for a match, worked out once on the server so the web, the app and Unity draw
 * the same shirts (it was a rule in SimMatch.vue, art.dart and KitColours). Moved letter for letter from the web:
 * the shirt and trim from the club's colours, the shorts from the trim when it contrasts, the ink on the shirt by its
 * brightness. Two similar shirts (Arsenal and Liverpool are both red): the away side changes to its own change kit
 * when it is far enough from the home shirt, else its second colour, else white, else navy. Integers only: a colour's
 * brightness is kept ×1000 (r·299 + g·587 + b·114), so the web's float comparisons hold exactly. Drawing only: it
 * never reaches the engine.
 */
class MatchKits
{
    private const WHITE = '#F3F0E6';

    private const NAVY = '#1C2333';

    /**
     * @param  array<string, mixed>  $home  a match view's club: primary/secondary (or color_primary/color_secondary), pattern, away_kit
     * @param  array<string, mixed>  $away
     * @return array{home: array<string, ?string>, away: array<string, ?string>}
     */
    public static function of(array $home, array $away): array
    {
        [$hp, $hs] = self::colours($home);
        [$ap, $as] = self::colours($away);
        $awayShirt = $ap;
        $awayTrim = $as;
        $awayPattern = $away['pattern'] ?? null;
        if (! self::far($hp, $awayShirt)) {
            $alt = $away['away_kit'] ?? null;
            $awayShirt = $alt && self::far($hp, $alt['color']) ? $alt['color']
                : (self::far($hp, $as) ? $as : (self::far($hp, self::WHITE) ? self::WHITE : self::NAVY));
            $awayTrim = $ap;
            $awayPattern = $alt && $awayShirt === $alt['color'] ? ($alt['pattern'] ?? null) : null;
        }

        return [
            'home' => self::make($hp, $hs, '#2E8B57', $home['pattern'] ?? null),
            'away' => self::make($awayShirt, $awayTrim, '#E9D70B', $awayPattern),
        ];
    }

    /** @return array<string, ?string> */
    private static function make(string $shirt, string $trim, string $gk, ?string $pattern): array
    {
        return [
            'shirt' => $shirt,
            'trim' => $trim,
            'shorts' => abs(self::lum($shirt) - self::lum($trim)) > 60000 ? $trim : $shirt,
            'socks' => $shirt,
            'text' => self::lum($shirt) > 150000 ? '#0A1F42' : '#FFFFFF',
            'gk' => $gk,
            'pattern' => $pattern,
        ];
    }

    /** @return array{0: string, 1: string} */
    private static function colours(array $c): array
    {
        return [
            $c['primary'] ?? $c['color_primary'] ?? '#163360',
            $c['secondary'] ?? $c['color_secondary'] ?? '#F7F4EA',
        ];
    }

    /** @return array{0: int, 1: int, 2: int} */
    private static function rgb(string $hex): array
    {
        return [hexdec(substr($hex, 1, 2)), hexdec(substr($hex, 3, 2)), hexdec(substr($hex, 5, 2))];
    }

    /** Brightness ×1000. */
    private static function lum(string $hex): int
    {
        [$r, $g, $b] = self::rgb($hex);

        return $r * 299 + $g * 587 + $b * 114;
    }

    private static function far(string $x, string $y): bool
    {
        $a = self::rgb($x);
        $b = self::rgb($y);

        return abs($a[0] - $b[0]) + abs($a[1] - $b[1]) + abs($a[2] - $b[2]) > 160;
    }
}
