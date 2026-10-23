<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\LeagueMembership;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * A coach leaves a league [PLAN 2.1, 2.2]: kicked by the owner, away too long, or (later) resigned.
 * The club goes back to a bot as it is (squad, money, place), free for another coach, and the coach
 * cannot come back to the same league this season. His open offers and listings are cancelled, and the
 * training slots empty (a bot does not train); a stadium part under way finishes with the club.
 */
class Leaving
{
    public const REASONS = ['resigned', 'absent', 'kicked', 'deleted'];

    /** False when the coach had already left (a kick and the absence check in the same moment). */
    public static function leave(LeagueMembership $membership, string $reason, ?string $kickReason = null): bool
    {
        if (! in_array($reason, self::REASONS, true)) {
            throw new \InvalidArgumentException($reason);
        }

        return DB::transaction(function () use ($membership, $reason, $kickReason) {
            $now = GameClock::now();
            $left = DB::table('league_memberships')->where('id', $membership->id)->whereNull('left_at')
                ->update(['left_at' => $now, 'left_reason' => $reason, 'kick_reason' => $kickReason, 'updated_at' => $now]);
            if ($left !== 1) {
                return false;
            }
            DB::table('clubs')->where('id', $membership->club_id)->where('user_id', $membership->user_id)
                ->update(['user_id' => null, 'updated_at' => $now]);
            // A bot keeps no deals: the coach's open offers (made or received) and his listings go [Sprint 37].
            DB::table('transfer_offers')->where('status', 'pending')
                ->where(fn ($q) => $q->where('from_club_id', $membership->club_id)->orWhere('to_club_id', $membership->club_id))
                ->update(['status' => 'cancelled', 'decided_at' => $now, 'updated_at' => $now]);
            DB::table('transfer_listings')->where('club_id', $membership->club_id)->delete();
            DB::table('training_slots')->where('club_id', $membership->club_id)->delete();
            // The coach is told why [Sprint 22 B2]; one who resigned or deleted the account knows.
            if (in_array($reason, ['absent', 'kicked'], true)) {
                Inbox::send($membership->user_id, $reason === 'absent' ? 'left_absent' : 'kicked', [
                    'league' => DB::table('leagues')->where('id', $membership->league_id)->value('name'),
                    'club' => DB::table('clubs')->where('id', $membership->club_id)->value('name'), 'reason' => $kickReason,
                ], $membership->league_id);
            }

            return true;
        });
    }

    /**
     * A coach resigns [PLAN 2.2, Sprint 32]: allowed except in the preparation (the summer window), on the winter
     * transfer day, and in the last 25% of the league rounds. He cannot come back to this league this season.
     */
    public static function resign(LeagueMembership $membership): void
    {
        if ($membership->left_at !== null) {
            throw new HttpException(409, 'غادرت هذا الدوري من قبل.');
        }
        if ($membership->user_id === $membership->league->owner_id) {
            throw new HttpException(409, 'منشئ الدوري لا يستقيل منه، فهو يديره.');
        }
        $season = $membership->league->season;
        $now = GameClock::now();
        $windows = DB::table('transfer_windows')->where('season_id', $season->id)->get()->keyBy('kind');
        $summer = $windows['summer'] ?? null;
        if ($membership->league->status !== 'running' || ($summer && $now->lt($summer->closes_at))) {
            throw new HttpException(409, 'لا استقالة في فترة الإعداد. يمكنك الاستقالة بعد أن تبدأ الجولات.');
        }
        $winter = $windows['winter'] ?? null;
        if ($winter && $now->gte($winter->opens_at) && $now->lt($winter->closes_at)) {
            throw new HttpException(409, 'لا استقالة في يوم الانتقالات الشتوي.');
        }
        if ($season->inLastQuarter()) {
            throw new HttpException(409, 'لا استقالة في آخر ربع من جولات الدوري.');
        }
        self::leave($membership, 'resigned') || throw new HttpException(409, 'غادرت هذا الدوري من قبل.');
    }

    /** The owner sends a coach away with a reason every member sees [PLAN 2.1]. */
    public static function kick(LeagueMembership $membership, string $reason): void
    {
        if ($membership->left_at !== null) {
            throw new HttpException(409, 'غادر هذا المدرب الدوري من قبل.');
        }
        if ($membership->user_id === $membership->league->owner_id) {
            throw new HttpException(409, 'لا يمكنك طرد نفسك.');
        }
        self::leave($membership, 'kicked', $reason) || throw new HttpException(409, 'غادر هذا المدرب الدوري من قبل.');
    }
}
