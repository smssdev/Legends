<?php

namespace App\League;

use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Club money [PLAN 2.7]: integers only, one row per movement that is never changed, and the balance
 * kept on the club in the same transaction. Every movement has its idempotency key, so a double tap
 * or a retry on a weak network posts it once. A spend is one conditional update (enough money, and
 * never below zero) checked by its affected rows, because lockForUpdate does nothing on SQLite.
 */
class ClubLedger
{
    public const TYPES = ['opening', 'handover_gift', 'handover_trim', 'wages', 'win_bonus', 'draw_bonus', 'sponsor', 'tickets',
        'league_prize', 'cup_prize', 'forced_sale', 'pool_buy', 'pool_sale', 'bot_buy', 'bot_sale', 'transfer_buy', 'transfer_sale', 'scout', 'scout_refund'];

    /** The money a club starts with (not income). */
    public const START = ['opening', 'handover_gift', 'handover_trim'];

    /** Each movement's name on the finance page. */
    public const LABELS = ['opening' => 'ميزانية البداية', 'handover_gift' => 'هدية الاستلام', 'handover_trim' => 'تعديل الاستلام',
        'wages' => 'الرواتب', 'win_bonus' => 'مكافأة فوز', 'draw_bonus' => 'مكافأة تعادل', 'sponsor' => 'الرعاة', 'tickets' => 'التذاكر',
        'league_prize' => 'جائزة الدوري', 'cup_prize' => 'جائزة الكأس', 'forced_sale' => 'بيع إجباري',
        'pool_buy' => 'شراء من المجموعة', 'pool_sale' => 'بيع للمجموعة', 'bot_buy' => 'شراء من نادي الحاسوب', 'bot_sale' => 'بيع لمدرب',
        'transfer_buy' => 'صفقة: شراء', 'transfer_sale' => 'صفقة: بيع',
        'scout' => 'الكشاف', 'scout_refund' => 'رد مبلغ الكشاف'];

    /**
     * Post one movement and return the balance after it. With $spend, a debit needs the money
     * (a club in debt cannot spend); without it the balance may go below zero (wages, later).
     * The same key again returns the first result and changes nothing.
     */
    public static function post(int $clubId, string $type, int $amount, string $key, ?string $reference = null, bool $spend = false): int
    {
        if (! in_array($type, self::TYPES, true)) {
            throw new \InvalidArgumentException("Unknown club transaction type: {$type}");
        }

        return DB::transaction(function () use ($clubId, $type, $amount, $key, $reference, $spend) {
            $done = DB::table('club_transactions')->where('idempotency_key', $key)->first();
            if ($done) {
                if ((int) $done->club_id !== $clubId || (int) $done->amount !== $amount) {
                    throw new \LogicException("Idempotency key {$key} was used for another movement.");
                }

                return (int) $done->balance_after;
            }
            $update = DB::table('clubs')->where('id', $clubId);
            if ($spend && $amount < 0) {
                $update->where('balance', '>=', -$amount);
            }
            if ($update->update(['balance' => DB::raw('balance + '.$amount)]) !== 1) {
                throw new HttpException(409, 'رصيد النادي لا يكفي.');
            }
            $balance = (int) DB::table('clubs')->where('id', $clubId)->value('balance');
            DB::table('club_transactions')->insert([
                'club_id' => $clubId, 'type' => $type, 'amount' => $amount, 'balance_after' => $balance,
                'idempotency_key' => $key, 'reference' => $reference, 'created_at' => GameClock::now(),
            ]);

            return $balance;
        });
    }

    /** The balance worked out from the movements alone: must always equal the club's balance. */
    public static function sum(int $clubId): int
    {
        return (int) DB::table('club_transactions')->where('club_id', $clubId)->sum('amount');
    }
}
