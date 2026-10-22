<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\LeagueMembership;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Who is still around [PLAN 2.2]. Any visit to a league's pages (or a change in it) is activity, kept
 * on the membership, not the account. From the season's start, 48 hours without it brings a warning
 * and 3 days send the coach away. A holiday of up to 7 days, once a season, stops the count.
 */
class Presence
{
    /** Activity in a league: at most one write a minute, and it clears the warning. */
    public static function touch(int $userId, int $leagueId): void
    {
        $now = GameClock::now();
        DB::table('league_memberships')->where('league_id', $leagueId)->where('user_id', $userId)->whereNull('left_at')
            ->where(fn ($q) => $q->whereNull('last_active_at')->orWhere('last_active_at', '<', $now->copy()->subMinute())->orWhereNotNull('absence_warned_at'))
            ->update(['last_active_at' => $now, 'absence_warned_at' => null, 'updated_at' => $now]);
    }

    public static function onHoliday(LeagueMembership $m, ?Carbon $at = null): bool
    {
        $at ??= GameClock::now();

        return $m->vacation_from !== null && $m->vacation_from->lte($at) && $m->vacation_until->gt($at);
    }

    /**
     * When the quiet time started: the last activity, but never before the season starts (who joins
     * before it is not counted) and never inside a holiday. Null while on holiday or before the start.
     */
    public static function quietSince(LeagueMembership $m, Carbon $seasonStart, ?Carbon $at = null): ?Carbon
    {
        $at ??= GameClock::now();
        if ($seasonStart->gt($at) || self::onHoliday($m, $at)) {
            return null;
        }
        $since = collect([$m->last_active_at, $m->joined_at, $seasonStart, $m->vacation_until?->lte($at) ? $m->vacation_until : null])
            ->filter()->max();

        return $since;
    }

    /** Every minute: warn at 48 hours, send away at 3 days. Returns [warned, sent away]. */
    public static function check(): array
    {
        $now = GameClock::now();
        $warnAfter = config('game.league.absence_warning_hours') * 3600;
        $leaveAfter = config('game.league.absence_days') * 86400;
        $warned = $gone = 0;
        $members = LeagueMembership::query()->whereNull('league_memberships.left_at')
            ->join('seasons', 'seasons.id', '=', 'league_memberships.season_id')
            ->join('leagues', 'leagues.id', '=', 'league_memberships.league_id')
            ->where('leagues.status', 'running')->where('seasons.status', 'running')
            ->select('league_memberships.*', 'seasons.starts_at as season_starts_at')->get();
        foreach ($members as $m) {
            $since = self::quietSince($m, Carbon::parse($m->season_starts_at), $now);
            if ($since === null) {
                continue;
            }
            $quiet = $since->diffInSeconds($now);
            if ($quiet >= $leaveAfter) {
                $gone += Leaving::leave($m, 'absent') ? 1 : 0;
            } elseif ($quiet >= $warnAfter && $m->absence_warned_at === null) {
                $told = DB::table('league_memberships')->where('id', $m->id)->whereNull('absence_warned_at')
                    ->update(['absence_warned_at' => $now]);
                $warned += $told;
                if ($told) {
                    Inbox::send($m->user_id, 'absence_warning', ['league' => DB::table('leagues')->where('id', $m->league_id)->value('name'),
                        'league_id' => $m->league_id], $m->league_id, $m->club_id);
                }
            }
        }

        return [$warned, $gone];
    }

    /** Start a holiday of up to 7 days, once a season [PLAN 2.2]. */
    public static function startHoliday(LeagueMembership $m, int $days): void
    {
        $now = GameClock::now();
        $set = DB::table('league_memberships')->where('id', $m->id)->whereNull('left_at')->whereNull('vacation_from')
            ->update(['vacation_from' => $now, 'vacation_until' => $now->copy()->addDays($days), 'absence_warned_at' => null, 'last_active_at' => $now, 'updated_at' => $now]);
        if ($set !== 1) {
            throw new HttpException(409, 'استخدمت إجازة هذا الموسم من قبل.');
        }
    }

    /** Come back early: the holiday ends now, and it still counts as this season's one. */
    public static function endHoliday(LeagueMembership $m): void
    {
        $now = GameClock::now();
        $ended = DB::table('league_memberships')->where('id', $m->id)->whereNull('left_at')->where('vacation_until', '>', $now)
            ->update(['vacation_until' => $now, 'last_active_at' => $now, 'updated_at' => $now]);
        if ($ended !== 1) {
            throw new HttpException(409, 'لست في إجازة الآن.');
        }
    }
}
