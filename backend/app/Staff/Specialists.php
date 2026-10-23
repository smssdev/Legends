<?php

namespace App\Staff;

use App\Economy\Economy;
use App\League\ClubLedger;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Specialists [docs/features/specialists.md, Sprint 31]: the doctor, the lawyer, the keeper coach and the physio,
 * each on a contract of a week scaled by the season's length, paid when signed. Their effects are read where the
 * game does the thing they change: the keeper coach in the match's first state (LeagueMatch), the other three when
 * the result is applied (MatchResult).
 */
class Specialists
{
    public const TYPES = ['doctor', 'lawyer', 'keeper_coach', 'physio'];

    public static function cost(int $leagueId, string $type): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config("game.specialists.cost_bp.{$type}"), 10000);
    }

    public static function seconds(int $leagueId): int
    {
        $scale = (int) DB::table('leagues')->where('id', $leagueId)->value('timer_scale');

        return max(60, intdiv((int) config('game.specialists.contract_days') * 86400 * ($scale ?: 10000), 10000));
    }

    /** The contract of this type working now, if any. */
    public static function current(int $clubId, string $type): ?object
    {
        $now = GameClock::now();

        return DB::table('staff_specialists')->where('club_id', $clubId)->where('type', $type)
            ->where('starts_at', '<=', $now)->where('ends_at', '>', $now)->first();
    }

    public static function has(int $clubId, string $type): bool
    {
        return self::current($clubId, $type) !== null;
    }

    public static function hire(int $clubId, string $type, string $key): void
    {
        DB::transaction(function () use ($clubId, $type, $key) {
            if (DB::table('staff_specialists')->where('idempotency_key', $key)->exists()) {
                return;
            }
            if (self::has($clubId, $type)) {
                throw new HttpException(409, 'لديك هذا الأخصائي الآن، جدّد عقده بعد أن ينتهي.');
            }
            $league = (int) DB::table('clubs')->where('id', $clubId)->value('league_id');
            $cost = self::cost($league, $type);
            $now = GameClock::now();
            $id = DB::table('staff_specialists')->insertGetId(['club_id' => $clubId, 'type' => $type, 'cost' => $cost,
                'starts_at' => $now, 'ends_at' => $now->copy()->addSeconds(self::seconds($league)), 'idempotency_key' => $key,
                'created_at' => $now, 'updated_at' => $now]);
            ClubLedger::post($clubId, 'specialist', -$cost, "specialist:{$id}", "specialist:{$type}", spend: true);
        });
    }

    /** The lawyer's call on one red card: cancelled or not, from the match's seed and the player. */
    public static function lawyerCancels(int $seed, int $playerId): bool
    {
        return crc32("lawyer:{$seed}:{$playerId}") % 10000 < (int) config('game.specialists.lawyer_cancel_bp');
    }
}
