<?php

namespace App\Wallet;

use App\Support\GameClock;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 64 B4] What a spend leaves before it is made, as buying a player shows it: the price in its currency, what the
 * club (or its coach, in coins) has now, what is left after, and when what it buys ends. The screens only show it.
 */
class SpendQuote
{
    /**
     * @param  array{currency: string, amount: int}  $price
     * @return array{currency: string, amount: int, have: int, after: int, can: bool, ends_at: ?string}
     */
    public static function of(int $clubId, array $price, ?CarbonInterface $endsAt): array
    {
        $club = DB::table('clubs')->where('id', $clubId)->first(['balance', 'user_id']);
        $have = $price['currency'] === 'coins' ? Wallet::balance((int) $club->user_id) : (int) $club->balance;

        return ['currency' => $price['currency'], 'amount' => (int) $price['amount'], 'have' => $have, 'after' => $have - (int) $price['amount'],
            'can' => $have >= (int) $price['amount'], 'ends_at' => $endsAt?->copy()->utc()->toIso8601ZuluString()];
    }

    /** Club money, ending this many seconds from now. */
    public static function money(int $clubId, int $amount, int $seconds): array
    {
        return self::of($clubId, ['currency' => 'money', 'amount' => $amount], GameClock::now()->addSeconds($seconds));
    }
}
