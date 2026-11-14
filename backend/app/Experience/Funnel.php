<?php

namespace App\Experience;

use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 64 B2] The new coaches' first five minutes, for the admin panel: of the accounts made in the last $days days
 * (guests left out), how many started and finished the intro match, took a club, saved a lineup and played a match.
 * Read from the game itself (the intro's two stamps are the only new data, in the privacy policy), never per person.
 */
class Funnel
{
    public const STEPS = ['signed_up', 'intro_started', 'intro_finished', 'club_taken', 'first_lineup', 'first_match'];

    public static function of(int $days): array
    {
        $from = GameClock::now()->subDays($days);
        $users = DB::table('users')->where('created_at', '>=', $from)->whereNull('guest_at');
        $ids = (clone $users)->pluck('id');
        $clubs = DB::table('league_memberships')->whereIn('league_memberships.user_id', $ids)->whereNotNull('league_memberships.club_id');
        $count = [
            'signed_up' => $ids->count(),
            'intro_started' => (clone $users)->whereNotNull('intro_started_at')->count(),
            'intro_finished' => (clone $users)->whereNotNull('intro_finished_at')->count(),
            'club_taken' => (clone $clubs)->distinct()->count('league_memberships.user_id'),
            // A lineup saved by the coach: changed after it was made.
            'first_lineup' => (clone $clubs)->join('lineups', 'lineups.club_id', '=', 'league_memberships.club_id')
                ->whereColumn('lineups.updated_at', '>', 'lineups.created_at')->distinct()->count('league_memberships.user_id'),
            'first_match' => (clone $clubs)->whereExists(fn ($q) => $q->select(DB::raw(1))->from('fixtures')->where('fixtures.status', 'finished')->where('fixtures.is_bye', false)
                ->where(fn ($q) => $q->whereColumn('fixtures.home_id', 'league_memberships.club_id')->orWhereColumn('fixtures.away_id', 'league_memberships.club_id')))
                ->distinct()->count('league_memberships.user_id'),
        ];
        $base = max(1, $count['signed_up']);

        return ['days' => $days, 'steps' => array_map(fn ($s) => ['step' => $s, 'count' => $count[$s], 'pct' => intdiv($count[$s] * 100, $base)], self::STEPS)];
    }
}
