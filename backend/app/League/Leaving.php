<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\League;
use App\Models\LeagueMembership;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * A coach leaves a league [PLAN 2.1, 2.2]: kicked by the owner, away too long, or resigned. Its creator neither resigns
 * nor is sent away; gone from the game, he hands the league on (handOver, Sprint 43 C2).
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
            // [Sprint 43 C2] A creator who deleted his account hands the league on.
            if ($reason === 'deleted') {
                self::handOver($membership->league_id, $membership->user_id);
            }
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

    /**
     * [Sprint 43 C2, Hamza 2026-11-05] The creator gone from the game: the league passes to one of its coaches at
     * random among those active lately, told in his inbox, and a statement in the league's news. Nothing when he is
     * not its creator or no active coach is left. Returns the new creator's id.
     */
    public static function handOver(int $leagueId, int $from): ?int
    {
        $league = League::find($leagueId);
        if (! $league || $league->owner_id !== $from) {
            return null;
        }
        $coaches = DB::table('league_memberships')->where('league_id', $leagueId)->whereNull('left_at')->whereNotNull('club_id')
            ->where('user_id', '!=', $from)->where('last_active_at', '>', GameClock::now()->subDays((int) config('game.league.absence_days')))
            ->orderBy('user_id')->pluck('user_id')->unique()->values()->all();
        if (! $coaches) {
            return null;
        }
        $to = (int) $coaches[random_int(0, count($coaches) - 1)];
        if (DB::table('leagues')->where('id', $leagueId)->where('owner_id', $from)->update(['owner_id' => $to, 'updated_at' => GameClock::now()]) !== 1) {
            return null;
        }
        $names = DB::table('users')->whereIn('id', [$from, $to])->pluck('name', 'id');
        [$season, $round] = Newspaper::writingRound($leagueId);
        $now = GameClock::now();
        DB::table('league_articles')->insert(['league_id' => $leagueId, 'user_id' => $to, 'status' => 'published', 'season_id' => $season, 'round' => $round,
            'title' => __('بيان: انتقال إدارة الدوري'),
            'body' => sprintf(__('غاب منشئ الدوري %s عن اللعبة، فانتقلت إدارة الدوري بالقرعة إلى المدرب %s.'), $names[$from] ?? '', $names[$to] ?? ''),
            'decided_at' => $now, 'created_at' => $now, 'updated_at' => $now]);
        Inbox::send($to, 'league_owner', ['from' => $names[$from] ?? '', 'league' => $league->name, 'league_id' => $leagueId], $leagueId);

        return $to;
    }
}
