<?php

namespace App\Data;

/**
 * A club's generated badge as SVG [PLAN 2.6]: no real logos, so each club gets a shield shape,
 * a pattern in its two colours and its three letters. The shape and pattern come from the club's
 * name, so a club always looks the same, on the web, in the app and in a replay.
 */
class Crest
{
    private const SHAPES = [
        // heater shield
        'M10 8 H110 V62 C110 98 82 118 60 128 C38 118 10 98 10 62 Z',
        // round badge
        'M60 6 A60 60 0 1 1 59.9 6 Z',
        // rounded top, pointed bottom
        'M10 30 Q10 6 34 6 H86 Q110 6 110 30 V74 L60 128 L10 74 Z',
        // flat top, round bottom
        'M8 8 H112 V64 A52 56 0 0 1 8 64 Z',
    ];

    private const PATTERNS = ['plain', 'stripes', 'sash', 'halves', 'chevron'];

    public static function svg(string $name, string $code, string $primary, string $secondary): string
    {
        $hash = crc32($name);
        $shape = self::SHAPES[$hash % count(self::SHAPES)];
        $pattern = self::PATTERNS[intdiv($hash, 7) % count(self::PATTERNS)];
        $id = 'c'.dechex($hash);
        $ink = self::light($primary) ? (self::light($secondary) ? '#0A1F42' : $secondary) : '#FFFFFF';
        $ring = strcasecmp($primary, $secondary) === 0 ? '#F5B82E' : $secondary;
        $art = match ($pattern) {
            'stripes' => "<path d='M36 0 h16 v134 h-16 Z M68 0 h16 v134 h-16 Z' fill='$secondary' opacity='.55'/>",
            'sash' => "<path d='M-10 30 L30 -10 L130 90 L90 130 Z' fill='$secondary' opacity='.55'/>",
            'halves' => "<rect x='60' y='0' width='70' height='134' fill='$secondary' opacity='.45'/>",
            'chevron' => "<path d='M0 50 L60 84 L120 50 V70 L60 104 L0 70 Z' fill='$secondary' opacity='.55'/>",
            default => '',
        };
        $code = htmlspecialchars(mb_strtoupper(mb_substr($code, 0, 3)), ENT_XML1);

        return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 120 134' role='img' aria-label='$code'>"
            ."<defs><clipPath id='$id'><path d='$shape'/></clipPath></defs>"
            ."<g clip-path='url(#$id)'><rect width='120' height='134' fill='$primary'/>$art</g>"
            ."<path d='$shape' fill='none' stroke='$ring' stroke-width='6' stroke-linejoin='round'/>"
            ."<text x='60' y='78' text-anchor='middle' font-family='Barlow Condensed, Arial Narrow, Arial, sans-serif' font-weight='800' font-size='38' fill='$ink' stroke='rgba(0,0,0,.25)' stroke-width='1'>$code</text>"
            .'</svg>';
    }

    private static function light(string $hex): bool
    {
        $n = hexdec(ltrim($hex, '#'));

        return (($n >> 16) * 299 + (($n >> 8) & 255) * 587 + ($n & 255) * 114) / 1000 > 150;
    }
}
