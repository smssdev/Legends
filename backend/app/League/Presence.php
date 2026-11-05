<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\LeagueMembership;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Who is still around [PLAN 2.2]. Any visit to a league's pages (or a change in it) is activity, kept
 * on the membership, not the account. From the season's start, 48 hours without it brings a warning
 * and 3 days send the coach away. A holiday stops the count: the account's own, in every league at once, or one
 * league's alone, of up to 7 days once a season, asked for with a reason its owner approves [X4, 2026-10-24].
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

        return ($m->vacation_from !== null && $m->vacation_from->lte($at) && $m->vacation_until->gt($at))
            || (bool) $m->user?->onVacation($at);
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
        $account = $m->user?->vacation_until;
        $since = collect([$m->last_active_at, $m->joined_at, $seasonStart, $m->vacation_until?->lte($at) ? $m->vacation_until : null, $account?->lte($at) ? $account : null])
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
            ->select('league_memberships.*', 'seasons.starts_at as season_starts_at')->with('user')->get();
        foreach ($members as $m) {
            $since = self::quietSince($m, Carbon::parse($m->season_starts_at), $now);
            if ($since === null) {
                continue;
            }
            $quiet = $since->diffInSeconds($now);
            if ($quiet >= $leaveAfter) {
                // [Sprint 43 C2] The creator is never sent away as creator: the league first passes to another coach at
                // random (a statement in its news), then he leaves like any coach away too long. With nobody to take
                // it, he stays.
                if ($m->user_id === (int) DB::table('leagues')->where('id', $m->league_id)->value('owner_id')
                    && Leaving::handOver($m->league_id, $m->user_id) === null) {
                    continue;
                }
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

    /**
     * Ask for a holiday in this league alone, with a reason [X4]: its owner approves or refuses it. The owner's own
     * request starts at once, since nobody else runs the league. One holiday a season, one request at a time.
     */
    public static function askHoliday(LeagueMembership $m, int $days, string $reason, bool $owner): void
    {
        $now = GameClock::now();
        $set = DB::table('league_memberships')->where('id', $m->id)->whereNull('left_at')->whereNull('vacation_from')->whereNull('vacation_requested_at')
            ->update(['vacation_request_days' => $days, 'vacation_reason' => $reason, 'vacation_requested_at' => $now, 'last_active_at' => $now, 'updated_at' => $now]);
        if ($set !== 1) {
            throw new HttpException(409, $m->vacation_from ? 'استخدمت إجازة هذا الموسم من قبل.' : 'طلبك للإجازة ينتظر رد مسؤول الدوري.');
        }
        if ($owner) {
            self::decide($m->fresh(), true);

            return;
        }
        $league = DB::table('leagues')->where('id', $m->league_id)->first(['name', 'owner_id']);
        Inbox::send($league->owner_id, 'vacation_request', ['league' => $league->name, 'league_id' => $m->league_id,
            'coach' => $m->user?->name, 'days' => $days, 'reason' => $reason], $m->league_id);
    }

    /** The owner's answer to a holiday request: approved, it starts now for the days asked; refused, it can be asked again. */
    public static function decide(LeagueMembership $m, bool $approve): void
    {
        $now = GameClock::now();
        $days = (int) $m->vacation_request_days;
        $set = DB::table('league_memberships')->where('id', $m->id)->whereNull('left_at')->whereNull('vacation_from')->whereNotNull('vacation_requested_at')
            ->update($approve
                ? ['vacation_from' => $now, 'vacation_until' => $now->copy()->addDays($days), 'vacation_requested_at' => null, 'absence_warned_at' => null, 'last_active_at' => $now, 'updated_at' => $now]
                : ['vacation_requested_at' => null, 'vacation_request_days' => null, 'updated_at' => $now]);
        if ($set !== 1) {
            throw new HttpException(409, 'لا يوجد طلب إجازة ينتظر الرد.');
        }
        $league = DB::table('leagues')->where('id', $m->league_id)->value('name');
        if ((int) DB::table('leagues')->where('id', $m->league_id)->value('owner_id') !== (int) $m->user_id) {
            Inbox::send($m->user_id, $approve ? 'vacation_approved' : 'vacation_rejected', ['league' => $league, 'league_id' => $m->league_id, 'days' => $days], $m->league_id, $m->club_id);
        }
    }

    public static function endAccountHoliday(User $user): void
    {
        $now = GameClock::now();
        $ended = DB::table('users')->where('id', $user->id)->where('vacation_until', '>', $now)->update(['vacation_until' => $now, 'updated_at' => $now]);
        if ($ended !== 1) {
            throw new HttpException(409, 'لست في إجازة الآن.');
        }
        // [UP13] Back early: the holiday's own row ends now too (the rest before the next one counts from here).
        DB::table('account_vacations')->where('user_id', $user->id)->where('ends_at', '>', $now)->update(['ends_at' => $now, 'updated_at' => $now]);
        DB::table('league_memberships')->where('user_id', $user->id)->whereNull('left_at')->update(['last_active_at' => $now]);
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
