<?php

namespace App\Wallet;

use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The premium coins [docs/features/premium.md, Sprint 34]: an account's wallet. Every movement goes through post()
 * once by its key, with a conditional update so the balance never goes below zero. Earning is in the game only;
 * spending is in a league (pay()), never in a fair league, within the season cap, and never turns into club money.
 */
class Wallet
{
    public const TYPES = ['welcome', 'league_custom', 'daily', 'win', 'draw', 'objective', 'title', 'spy', 'secret_training', 'specialist', 'finish_training', 'finish_scout', 'finish_stadium', 'quick_sale', 'bribe', 'security_check', 'double_agent'];

    public const LABELS = ['welcome' => 'مكافأة توثيق الحساب', 'league_custom' => 'إنشاء دوري مخصص', 'daily' => 'مكافأة اليوم', 'win' => 'فوز', 'draw' => 'تعادل', 'objective' => 'تحقيق هدف', 'title' => 'لقب',
        'spy' => 'التجسس', 'secret_training' => 'التدريب السري', 'specialist' => 'أخصائي', 'finish_training' => 'إنهاء جلسة تدريب', 'quick_sale' => 'بيع فوري',
        'finish_scout' => 'إنهاء بحث الكشاف', 'finish_stadium' => 'إنهاء جزء الملعب', 'bribe' => 'مصاريف خاصة', 'security_check' => 'فحص أمني', 'double_agent' => 'جاسوس مزدوج'];

    public static function balance(int $userId): int
    {
        return (int) DB::table('wallets')->where('user_id', $userId)->value('balance');
    }

    public static function sum(int $userId): int
    {
        return (int) DB::table('wallet_transactions')->where('user_id', $userId)->sum('amount');
    }

    /** One movement, once by its key. A spend fails rather than go below zero. Returns the balance after. */
    public static function post(int $userId, string $type, int $amount, string $key, ?string $reference = null, ?int $leagueId = null, ?int $seasonId = null): int
    {
        if (! in_array($type, self::TYPES, true)) {
            throw new \InvalidArgumentException("Unknown wallet transaction type: {$type}");
        }

        return DB::transaction(function () use ($userId, $type, $amount, $key, $reference, $leagueId, $seasonId) {
            $done = DB::table('wallet_transactions')->where('idempotency_key', $key)->first();
            if ($done) {
                return (int) $done->balance_after;
            }
            DB::table('wallets')->insertOrIgnore(['user_id' => $userId, 'balance' => 0, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
            $update = DB::table('wallets')->where('user_id', $userId);
            if ($amount < 0) {
                $update->where('balance', '>=', -$amount);
            }
            if ($update->update(['balance' => DB::raw('balance + '.$amount), 'updated_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, 'رصيد الكوينز لا يكفي.');
            }
            $balance = self::balance($userId);
            DB::table('wallet_transactions')->insert(['user_id' => $userId, 'type' => $type, 'amount' => $amount, 'balance_after' => $balance,
                'league_id' => $leagueId, 'season_id' => $seasonId, 'idempotency_key' => $key, 'reference' => $reference, 'created_at' => GameClock::now()]);

            return $balance;
        });
    }

    /** Coins earned in the game: a win, an objective, a title... A bot's club earns nothing. */
    public static function earn(?int $userId, string $type, string $key, ?string $reference = null, ?int $leagueId = null, ?int $seasonId = null, ?string $amountKey = null): void
    {
        $amount = (int) config('game.premium.earn.'.($amountKey ?? $type));
        if ($userId && $amount > 0) {
            self::post($userId, $type, $amount, $key, $reference, $leagueId, $seasonId);
        }
    }

    /** Coins spent this season in this league. */
    public static function spentThisSeason(int $userId, int $leagueId, int $seasonId): int
    {
        return -(int) DB::table('wallet_transactions')->where('user_id', $userId)->where('league_id', $leagueId)->where('season_id', $seasonId)
            ->where('amount', '<', 0)->sum('amount');
    }

    /** Pay coins for something in a league: not in a fair league, within the season's cap. */
    public static function pay(int $userId, int $leagueId, string $type, int $coins, string $key, ?string $reference = null): void
    {
        $league = DB::table('leagues')->where('id', $leagueId)->first();
        if ($league->fair_league) {
            throw new HttpException(409, 'الدوري نزيه: لا تُصرف الكوينز فيه.');
        }
        if (DB::table('wallet_transactions')->where('idempotency_key', $key)->exists()) {
            return;
        }
        $season = (int) DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->value('id');
        $cap = (int) config('game.premium.season_cap');
        if (self::spentThisSeason($userId, $leagueId, $season) + $coins > $cap) {
            throw new HttpException(409, "بلغت سقف صرف الكوينز في هذا الدوري هذا الموسم ({$cap}).");
        }
        self::post($userId, $type, -$coins, $key, $reference, $leagueId, $season);
    }
}
