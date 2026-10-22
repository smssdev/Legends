<?php

namespace App\League;

use App\Models\LeagueMembership;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * A coach leaves a league [PLAN 2.1, 2.2]: kicked by the owner, away too long, or (later) resigned.
 * The club goes back to a bot as it is (squad, money, place), free for another coach, and the coach
 * cannot come back to the same league this season. Pending offers are cancelled here once the market
 * has them (Sprint 24); training and stadium timers stay with the club.
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

            return true;
        });
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
