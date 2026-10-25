<?php

namespace App\Wallet;

use App\League\ClubLedger;
use Illuminate\Support\Facades\DB;

/**
 * What a premium feature costs a club [docs/features/premium.md, Sprint 34]: coins from its coach's wallet, or, in
 * a fair league where coins are locked, club money at the feature's own price (Sprints 28 to 31).
 */
class Price
{
    /**
     * $coinsBp scales the coins with the money, for a feature with grades (the staff's stars, X20).
     *
     * @return array{currency: string, amount: int}
     */
    public static function quote(int $leagueId, string $feature, int $money, int $coinsBp = 10000): array
    {
        $fair = (bool) DB::table('leagues')->where('id', $leagueId)->value('fair_league');

        return $fair ? ['currency' => 'money', 'amount' => $money]
            : ['currency' => 'coins', 'amount' => max(1, intdiv((int) config("game.premium.price.{$feature}") * $coinsBp, 10000))];
    }

    /** Charge the club (its coach's coins, or its money in a fair league). Returns what was charged. */
    public static function charge(int $clubId, string $feature, int $money, string $key, string $reference, int $coinsBp = 10000): array
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        $quote = self::quote($club->league_id, $feature, $money, $coinsBp);
        if ($quote['currency'] === 'money') {
            ClubLedger::post($clubId, $feature, -$money, $key, $reference, spend: true);
        } else {
            Wallet::pay((int) $club->user_id, $club->league_id, $feature, $quote['amount'], "coins:{$key}", $reference);
        }

        return $quote;
    }
}
