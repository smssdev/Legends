<?php

namespace App\Market;

use App\League\ClubLedger;
use Illuminate\Support\Facades\DB;

/**
 * [X62 E2] The sell-on clause: a coach buying another coach's player may promise him bp of the player's next sale
 * (up to game.economy.sell_on_max_bp). It rides on the player until he is sold for money (a listing, a quick or a
 * forced sale, or another coach's offer): then the selling club pays it to the club that had sold him, once.
 */
class SellOn
{
    /** Promise it on players a club bought (none for 0). */
    public static function promise(array $playerIds, int $toClubId, int $bp): void
    {
        if ($bp > 0 && $playerIds) {
            DB::table('players')->whereIn('id', $playerIds)->update(['sell_on_club_id' => $toClubId, 'sell_on_bp' => $bp]);
        }
    }

    /** A sale for money: the share to the club owed it, and the clause is spent. Returns the share. */
    public static function settle(int $sellerClubId, int $playerId, int $price, string $key): int
    {
        $p = DB::table('players')->where('id', $playerId)->first(['sell_on_club_id', 'sell_on_bp']);
        if (! $p || ! $p->sell_on_club_id || $price <= 0) {
            return 0;
        }
        DB::table('players')->where('id', $playerId)->update(['sell_on_club_id' => null, 'sell_on_bp' => null]);
        if ((int) $p->sell_on_club_id === $sellerClubId || ! DB::table('clubs')->where('id', $p->sell_on_club_id)->exists()) {
            return 0;
        }
        $share = intdiv($price * (int) $p->sell_on_bp, 10000);
        if ($share > 0) {
            ClubLedger::post($sellerClubId, 'sell_on', -$share, "{$key}:sell_on:pay", "player:{$playerId}");
            ClubLedger::post((int) $p->sell_on_club_id, 'sell_on', $share, "{$key}:sell_on:get", "player:{$playerId}");
        }

        return $share;
    }
}
