<?php

namespace App\Data;

use Illuminate\Support\Facades\DB;

/**
 * [X76] A club's kit pattern, as the owner sets it in the data editor (master_clubs.kit_pattern). A league's club reads
 * its data club's, so a change shows in every league at once. Drawing only: it never reaches the engine.
 */
class KitPattern
{
    public const ALL = ['plain', 'stripes', 'hoops', 'halves', 'sash'];

    /** A data club's pattern (the simulator's clubs). */
    public static function ofMaster(?int $id): ?string
    {
        return $id ? self::clean(DB::table('master_clubs')->where('id', $id)->value('kit_pattern')) : null;
    }

    /** A league club's pattern, from its data club. */
    public static function ofClub(?int $id): ?string
    {
        return $id ? self::clean(DB::table('clubs')->join('master_clubs', 'master_clubs.id', '=', 'clubs.master_club_id')
            ->where('clubs.id', $id)->value('master_clubs.kit_pattern')) : null;
    }

    private static function clean(?string $p): ?string
    {
        return in_array($p, self::ALL, true) && $p !== 'plain' ? $p : null;
    }
}
