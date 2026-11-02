<?php

namespace App\Data;

use Illuminate\Support\Facades\DB;

/**
 * [X76] A club's kit pattern, as the owner sets it in the data editor (master_clubs.kit_pattern), and [Sprint 34 V1] its
 * change kit (away_color, away_pattern). A league's club reads its data club's, so a change shows in every league at
 * once. Drawing only: it never reaches the engine.
 */
class KitPattern
{
    public const ALL = ['plain', 'stripes', 'hoops', 'halves', 'sash'];

    /**
     * Everything a match screen draws of a club's kits: the pattern of its first kit and its change kit (or null).
     *
     * @return array{pattern: ?string, away_kit: ?array{color: string, pattern: ?string}}
     */
    public static function kits(?int $id, bool $league): array
    {
        $row = ! $id ? null : ($league
            ? DB::table('clubs')->join('master_clubs', 'master_clubs.id', '=', 'clubs.master_club_id')->where('clubs.id', $id)
                ->first(['master_clubs.kit_pattern', 'master_clubs.away_color', 'master_clubs.away_pattern'])
            : DB::table('master_clubs')->where('id', $id)->first(['kit_pattern', 'away_color', 'away_pattern']));

        return [
            'pattern' => self::clean($row?->kit_pattern),
            'away_kit' => $row?->away_color ? ['color' => $row->away_color, 'pattern' => self::clean($row->away_pattern)] : null,
        ];
    }

    private static function clean(?string $p): ?string
    {
        return in_array($p, self::ALL, true) && $p !== 'plain' ? $p : null;
    }
}
