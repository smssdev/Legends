<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/** Who belongs to a league: its owner and its coaches still in it [PLAN 2.13]. */
class Members
{
    public static function isMember(int $userId, int $leagueId): bool
    {
        return DB::table('leagues')->where('id', $leagueId)->where('owner_id', $userId)->exists()
            || DB::table('league_memberships')->where('league_id', $leagueId)->where('user_id', $userId)->whereNull('left_at')->exists();
    }
}
