<?php

namespace App\Market;

use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Selling a player [X6, 2026-10-24]. Every player has a sale cap: 130% of his value, or his value alone when the
 * club bought him (so buying and selling on never makes money from nothing; his training gains still count, since
 * training raises his value). A coach lists him at any price from half his value to the cap, and a buyer from
 * outside the league takes him at that price after a wait: an hour at half his value, six at his value, a day and
 * a half at the cap, scaled by the season's length and a little random. Every listed player is sold in the end;
 * another coach may still buy him first.
 */
class Buyer
{
    /** The most a player listed by this club may ask. */
    public static function cap(object $player, int $clubId, ?bool $bought = null): int
    {
        $bought ??= DB::table('club_transactions')->where('club_id', $clubId)->where('reference', "player:{$player->id}")
            ->whereIn('type', ['pool_buy', 'bot_buy'])->exists()
            || DB::table('player_moves')->where('player_id', $player->id)->where('to_club_id', $clubId)->exists();

        return intdiv((int) $player->value * ($bought ? 10000 : (int) config('game.economy.sale_cap_bp')), 10000);
    }

    /** The players of this club it bought (from the pool, a bot or another coach), for cap() over a whole squad in two queries. */
    public static function boughtIds(int $clubId): array
    {
        $refs = DB::table('club_transactions')->where('club_id', $clubId)->whereIn('type', ['pool_buy', 'bot_buy'])->whereLike('reference', 'player:%')->pluck('reference')
            ->map(fn ($r) => (int) substr($r, 7));

        return array_flip($refs->merge(DB::table('player_moves')->where('to_club_id', $clubId)->pluck('player_id'))->map(fn ($id) => (int) $id)->all());
    }

    /** The least a listing may ask: the floor of a fair price between coaches. */
    public static function floor(object $player): int
    {
        return intdiv((int) $player->value * (int) config('game.economy.human_trade_min_bp'), 10000);
    }

    /** The wait (seconds) for this price, before the random part: longer the nearer the price is to the cap. */
    public static function wait(int $price, int $value, int $leagueId, ?int $scale = null): int
    {
        $points = config('game.economy.virtual_buyer.hours_at_bp');
        ksort($points);
        $bp = $value > 0 ? intdiv($price * 10000, $value) : 10000;
        $keys = array_keys($points);
        $hours100 = $points[$keys[0]] * 100;
        if ($bp >= end($keys)) {
            $hours100 = $points[end($keys)] * 100;
        } else {
            for ($i = 1; $i < count($keys); $i++) {
                [$lo, $hi] = [$keys[$i - 1], $keys[$i]];
                if ($bp <= $hi && $bp >= $lo) {
                    $hours100 = $points[$lo] * 100 + intdiv(($points[$hi] - $points[$lo]) * 100 * ($bp - $lo), $hi - $lo);
                    break;
                }
            }
        }
        $scale = max(1, $scale ?? ((int) DB::table('leagues')->where('id', $leagueId)->value('timer_scale') ?: 10000));

        return max(60, intdiv($hours100 * 36 * $scale, 10000));
    }

    /** When a listing at this price sells: the wait, give or take jitter_bp. */
    public static function sellsAt(int $price, int $value, int $leagueId): Carbon
    {
        $wait = self::wait($price, $value, $leagueId);
        $jitter = (int) config('game.economy.virtual_buyer.jitter_bp');
        $wait = intdiv($wait * random_int(10000 - $jitter, 10000 + $jitter), 10000);

        return GameClock::now()->copy()->addSeconds(max(60, $wait));
    }

    /** Every minute: the listings whose time has come go to their buyer, while the market is open. */
    public static function due(): int
    {
        $n = 0;
        $due = DB::table('transfer_listings')->join('clubs', 'clubs.id', '=', 'transfer_listings.club_id')
            ->whereNotNull('transfer_listings.sells_at')->where('transfer_listings.sells_at', '<=', GameClock::now())
            ->select('transfer_listings.*', 'clubs.league_id', 'clubs.user_id')->orderBy('transfer_listings.sells_at')->get();
        foreach ($due as $l) {
            if (Market::closed((int) $l->league_id)) {
                continue;
            }
            $n += self::sell($l) ? 1 : 0;
        }

        return $n;
    }

    private static function sell(object $l): bool
    {
        return DB::transaction(function () use ($l) {
            $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->where('players.id', $l->player_id)->where('players.club_id', $l->club_id)->select('players.*', 'master_players.name', 'master_players.line')->first();
            if (! $p) {
                DB::table('transfer_listings')->where('id', $l->id)->delete();

                return false;
            }
            // A squad too small to let him go: the buyer comes back in an hour.
            $count = DB::table('players')->where('club_id', $l->club_id)->count();
            $keepers = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->where('players.club_id', $l->club_id)->where('master_players.line', 'gk')->count();
            if ($count - 1 < (int) config('game.economy.min_squad') || ($p->line === 'gk' && $keepers - 1 < (int) config('game.economy.min_keepers'))) {
                DB::table('transfer_listings')->where('id', $l->id)->update(['sells_at' => GameClock::now()->copy()->addHour()]);

                return false;
            }
            // He leaves the league: nobody in it can buy him back.
            $gone = DB::table('players')->where('id', $p->id)->where('club_id', $l->club_id)
                ->update(['club_id' => null, 'in_pool' => false, 'scouted_by' => null, 'updated_at' => GameClock::now()]);
            if ($gone !== 1) {
                return false;
            }
            Transfers::left((int) $p->id, (int) $l->club_id);
            ClubLedger::post((int) $l->club_id, 'listing_sale', (int) $l->price, "listing:{$l->id}:{$p->id}", "player:{$p->id}");
            Inbox::send($l->user_id ? (int) $l->user_id : null, 'listing_sold', ['player' => $p->name, 'price' => (int) $l->price,
                'league_id' => $l->league_id], (int) $l->league_id, (int) $l->club_id);

            return true;
        });
    }
}
