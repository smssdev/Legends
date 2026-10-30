<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\League;
use App\Models\LeagueJoinRequest;
use App\Models\LeagueMembership;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The way into a league [PLAN 2.1]: a request by code, the owner's approval, then taking a club
 * no coach has. Taking it is one conditional update checked by its affected rows inside an
 * IMMEDIATE transaction, so of many coaches reaching for the same club exactly one gets it.
 */
class Joining
{
    public static function request(User $user, League $league): LeagueJoinRequest
    {
        if ($league->isOwner($user)) {
            throw new HttpException(409, 'أنت منشئ هذا الدوري.');
        }
        self::assertCanEnter($user, $league);
        $existing = LeagueJoinRequest::where('league_id', $league->id)->where('user_id', $user->id)->first();
        if ($existing?->status === 'rejected') {
            throw new HttpException(409, 'رفض منشئ الدوري طلبك.');
        }
        if ($existing) {
            return $existing;
        }
        self::assertCanTakeAnother($user);

        try {
            $request = LeagueJoinRequest::create(['league_id' => $league->id, 'user_id' => $user->id, 'status' => 'pending']);
            Inbox::send($league->owner_id, 'join_request', ['league' => $league->name, 'league_id' => $league->id, 'user' => $user->name], $league->id);

            return $request;
        } catch (UniqueConstraintViolationException) {
            // The same request sent twice at once: the first one stands.
            return LeagueJoinRequest::where('league_id', $league->id)->where('user_id', $user->id)->firstOrFail();
        }
    }

    /** The owner approves or rejects a waiting request, whenever they like (it never expires) [PLAN 5]. */
    public static function decide(LeagueJoinRequest $request, bool $approve): LeagueJoinRequest
    {
        $changed = DB::table('league_join_requests')->where('id', $request->id)->where('status', 'pending')
            ->update(['status' => $approve ? 'approved' : 'rejected', 'decided_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        if ($changed !== 1) {
            throw new HttpException(409, 'تم البت في هذا الطلب من قبل.');
        }
        $league = League::find($request->league_id);
        Inbox::send($request->user_id, $approve ? 'join_approved' : 'join_rejected', ['league' => $league->name, 'league_id' => $league->id], $league->id);

        return $request->fresh();
    }

    /** May this account look at the clubs and take one: the owner, or an approved request. */
    public static function approved(User $user, League $league): bool
    {
        return $league->isOwner($user)
            || LeagueJoinRequest::where('league_id', $league->id)->where('user_id', $user->id)->where('status', 'approved')->exists();
    }

    /** Take a club no coach has. Returns the new membership; 409 "taken" when someone was first. */
    public static function claim(User $user, League $league, int $clubId): LeagueMembership
    {
        if (! self::approved($user, $league)) {
            throw new HttpException(403, 'ينتظر طلبك موافقة منشئ الدوري.');
        }

        // [X68] A tournament whose teams the draw shares out: none is taken by hand before the draw.
        if ($league->kind === 'tournament' && $league->entry_mode === 'draw' && ! $league->drawn_at) {
            throw new HttpException(409, __('الفرق في هذه البطولة توزعها القرعة على المشاركين. شارك من صفحة البطولة.'));
        }

        return DB::transaction(function () use ($user, $league, $clubId) {
            // Read again inside the transaction: it holds the write lock, so nothing moves under us.
            $league = $league->fresh();
            self::assertCanEnter($user, $league);
            self::assertCanTakeAnother($user);
            $season = $league->season;
            $taken = DB::table('clubs')->where('id', $clubId)->where('league_id', $league->id)->whereNull('user_id')
                ->update(['user_id' => $user->id, 'updated_at' => GameClock::now()]);
            if ($taken !== 1) {
                throw new HttpException(409, 'الفريق أُخذ، اختر فريقاً آخر.');
            }
            $now = GameClock::now();
            $membership = LeagueMembership::create([
                'league_id' => $league->id, 'season_id' => $season->id, 'user_id' => $user->id, 'club_id' => $clubId,
                'joined_at' => $now, 'last_active_at' => $now,
            ]);
            self::handover($league, $clubId, $membership->id);

            return $membership;
        });
    }

    /**
     * A club taken from a bot keeps its money only between 500,000 and the starting budget [PLAN 2.7]:
     * less is topped up as a gift, more is trimmed, so no one fills a bot to take it later and a late
     * coach never inherits more than the first ones had.
     */
    private static function handover(League $league, int $clubId, int $membershipId): void
    {
        $balance = (int) DB::table('clubs')->where('id', $clubId)->value('balance');
        $min = min(config('game.economy.handover_min'), $league->starting_budget);
        $max = $league->starting_budget;
        $target = max($min, min($max, $balance));
        if ($target !== $balance) {
            ClubLedger::post($clubId, $target > $balance ? 'handover_gift' : 'handover_trim', $target - $balance,
                "handover:{$membershipId}", "membership:{$membershipId}");
        }
    }

    /** The league is open to this account now: not finished, not in its last quarter, not already in or left this season. */
    private static function assertCanEnter(User $user, League $league): void
    {
        if ($league->status === 'finished') {
            throw new HttpException(409, 'انتهى هذا الدوري.');
        }
        $season = $league->season;
        if ($season->inLastQuarter()) {
            throw new HttpException(409, 'الانضمام مقفل في آخر ربع من جولات الدوري.');
        }
        $membership = LeagueMembership::where('league_id', $league->id)->where('season_id', $season->id)->where('user_id', $user->id)->first();
        if ($membership && $membership->left_at === null) {
            throw new HttpException(409, 'لديك فريق في هذا الدوري.');
        }
        if ($membership) {
            throw new HttpException(409, 'غادرت هذا الدوري هذا الموسم، ويمكنك العودة في الموسم الجديد.');
        }
    }

    /** A club in each league, up to the slots open for the account's age [PLAN 2.1, X18, Sprint 24 B3]. */
    public static function assertCanTakeAnother(User $user): void
    {
        $open = CoachSlots::open($user);
        if (self::activeTeams($user) >= $open) {
            $next = CoachSlots::next($user);
            throw new HttpException(409, $next
                ? sprintf(__('فتحاتك المفتوحة كلها مشغولة (%d). تُفتح فتحتك التالية بعد %d يوماً.'), $open, max(1, intdiv($next->getTimestamp() - GameClock::now()->getTimestamp() + 86399, 86400)))
                : sprintf(__('وصلت للحد: %d فرق نشطة في وقت واحد.'), $open));
        }
    }

    public static function activeTeams(User $user): int
    {
        return DB::table('league_memberships')->join('leagues', 'leagues.id', '=', 'league_memberships.league_id')
            ->where('league_memberships.user_id', $user->id)->whereNull('league_memberships.left_at')
            ->where('leagues.status', '!=', 'finished')->count();
    }
}
