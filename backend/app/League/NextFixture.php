<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/** A club's next match: scheduled, locked or being played, with both sides known. */
class NextFixture
{
    public static function of(int $clubId): ?object
    {
        return DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $clubId)->orWhere('away_id', $clubId))
            ->whereNotNull('home_id')->whereNotNull('away_id')->orderBy('scheduled_at')->first();
    }
}
