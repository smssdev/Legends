<?php

namespace App\Staff;

use App\Economy\Economy;
use App\Messages\Inbox;
use App\Support\GameClock;
use App\Wallet\Price;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The staff [docs/features/specialists.md, Sprint 31, X20]: a coach for each line (the keeper coach, and the defence,
 * midfield and attack coaches), the doctor, the physio and the lawyer, each on a contract of a week scaled by the
 * season's length and with 1 to 5 stars, paid when signed. More stars, a dearer contract and a bigger effect. Their
 * effects are read where the game does the thing they change: the line coaches in training (Training, Camp) and the
 * keeper coach in the match's first state (LeagueMatch), the other three when the result is applied (MatchResult).
 */
class Specialists
{
    public const TYPES = ['att_coach', 'mid_coach', 'def_coach', 'keeper_coach', 'physio', 'doctor', 'lawyer', 'mental_coach'];

    /** The coach of each line. */
    public const LINE_COACH = ['gk' => 'keeper_coach', 'def' => 'def_coach', 'mid' => 'mid_coach', 'att' => 'att_coach'];

    public static function cost(int $leagueId, string $type, int $stars = 3): int
    {
        return intdiv(intdiv(Economy::scale($leagueId) * (int) config("game.specialists.cost_bp.{$type}"), 10000)
            * (int) config("game.specialists.stars_cost_bp.{$stars}"), 10000);
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
            ->where('starts_at', '<=', $now)->where('ends_at', '>', $now)->orderByDesc('stars')->first();
    }

    /** A renewal signed and waiting for the current contract to end. */
    public static function next(int $clubId, string $type): ?object
    {
        return DB::table('staff_specialists')->where('club_id', $clubId)->where('type', $type)->where('starts_at', '>', GameClock::now())->first();
    }

    public static function has(int $clubId, string $type): bool
    {
        return self::current($clubId, $type) !== null;
    }

    /** The stars of the contract working now, 0 without one. */
    public static function stars(int $clubId, string $type): int
    {
        return (int) (self::current($clubId, $type)?->stars ?? 0);
    }

    /** An effect by the stars working now: the config table's value, or $none without a contract. */
    public static function effect(int $clubId, string $type, string $table, int $none = 0): int
    {
        $stars = self::stars($clubId, $type);

        return $stars ? (int) config("game.specialists.{$table}.{$stars}") : $none;
    }

    /** A training session's step with the line's coach: faster by the coach's stars [X20]. */
    public static function trainingStep(int $clubId, string $line, int $step): int
    {
        $bp = self::effect($clubId, self::LINE_COACH[$line] ?? '', 'coach_training_bp');

        return intdiv($step * (10000 + $bp), 10000);
    }

    /**
     * Sign a contract. With one working, only in its last renew_hours: the new one starts when it ends (a renewal,
     * at any stars). A renewal already signed refuses another.
     */
    public static function hire(int $clubId, string $type, string $key, int $stars = 3): void
    {
        DB::transaction(function () use ($clubId, $type, $key, $stars) {
            if (DB::table('staff_specialists')->where('idempotency_key', $key)->exists()) {
                return;
            }
            $league = (int) DB::table('clubs')->where('id', $clubId)->value('league_id');
            $now = GameClock::now();
            $starts = $now;
            if ($current = self::current($clubId, $type)) {
                $ends = Carbon::parse($current->ends_at, 'UTC');
                $window = intdiv((int) config('game.specialists.renew_hours') * 3600 * ((int) DB::table('leagues')->where('id', $league)->value('timer_scale') ?: 10000), 10000);
                if (self::next($clubId, $type)) {
                    throw new HttpException(409, 'جدّدت عقده من قبل، ويبدأ العقد الجديد حين ينتهي الحالي.');
                }
                if ($ends->copy()->subSeconds($window)->gt($now)) {
                    throw new HttpException(409, 'لديك هذا الأخصائي الآن. يُجدَّد عقده في آخر يوم منه.');
                }
                $starts = $ends;
            }
            $cost = self::cost($league, $type, $stars);
            $id = DB::table('staff_specialists')->insertGetId(['club_id' => $clubId, 'type' => $type, 'stars' => $stars, 'cost' => $cost,
                'starts_at' => $starts, 'ends_at' => $starts->copy()->addSeconds(self::seconds($league)), 'idempotency_key' => $key,
                'created_at' => $now, 'updated_at' => $now]);
            Price::charge($clubId, 'specialist', $cost, "specialist:{$id}", "specialist:{$type}", (int) config("game.specialists.stars_cost_bp.{$stars}"));
        });
    }

    /** The lawyer's call on one red card: cancelled or not, from the match's seed and the player, by his stars. */
    public static function lawyerCancels(int $clubId, int $seed, int $playerId): bool
    {
        return crc32("lawyer:{$seed}:{$playerId}") % 10000 < self::effect($clubId, 'lawyer', 'lawyer_cancel_bp');
    }

    /** Every minute: the contracts that ended unrenewed are resignations, and their coaches hear of them [X20]. */
    public static function due(): int
    {
        $n = 0;
        $now = GameClock::now();
        foreach (DB::table('staff_specialists')->where('ends_at', '<=', $now)->whereNull('left_notified_at')->get() as $c) {
            if (DB::table('staff_specialists')->where('id', $c->id)->whereNull('left_notified_at')->update(['left_notified_at' => $now]) !== 1) {
                continue;
            }
            $renewed = DB::table('staff_specialists')->where('club_id', $c->club_id)->where('type', $c->type)->where('starts_at', '>=', $c->ends_at)->exists();
            $club = DB::table('clubs')->where('id', $c->club_id)->first();
            if (! $renewed && $club?->user_id) {
                Inbox::send($club->user_id, 'staff_left', ['type' => $c->type, 'stars' => (int) $c->stars], $club->league_id, $club->id);
                $n++;
            }
        }

        return $n;
    }
}
