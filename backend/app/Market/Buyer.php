<?php

namespace App\Market;

use App\Economy\Economy;
use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Support\GameClock;
use App\TimedEvents\TimedEvents;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Selling a player [X6, 2026-10-24]. A coach lists up to max_listings players at any price from half the value to
 * the cap, and a buyer from outside the league takes each at that price after a wait: an hour at half his value, six
 * at his value, eight days at the cap, moved by his age and rating (the buyer's demand), scaled by the season's
 * length, a little random, and shorter in a transfer madness. Every listed player is sold in the end; another coach
 * may still buy him first.
 * The economy [Sprint 23, the owner's decision 2026-10-29]: what a club makes selling outside the league (to the
 * outside buyers and the instant sale) is its profit over the player's cost: what it paid for him (bought_for), or
 * his value when the season began for one of its own. That profit, from training, from a discount, or from asking up
 * to 250%, is capped in a season (sale_profit_bp_per_season of the league's money scale): the cap of a listing and
 * the instant sale's pay shrink to fit what is left of it.
 */
class Buyer
{
    /**
     * What this player cost his club: what it paid, his value when it bought him before Sprint 23 (not kept then), or
     * for one of its own his value when the season began.
     */
    public static function basis(object $player, ?array $bought = null): int
    {
        if (($player->bought_for ?? null) !== null) {
            return (int) $player->bought_for;
        }
        $bought ??= self::boughtIds((int) $player->club_id);

        return isset($bought[$player->id]) ? (int) $player->value : (int) ($player->base_value ?? $player->value);
    }

    /** The most a player listed by this club may ask: up to 250% of his value, within the season's profit room. */
    public static function cap(object $player, int $clubId, ?array $room = null, ?array $bought = null): int
    {
        $value = (int) $player->value;
        $room ??= self::room($clubId);

        return max(1, min(intdiv($value * (int) config('game.economy.sale_cap_bp'), 10000), self::basis($player, $bought) + self::leftFor($room, (int) $player->id)));
    }

    /** What the instant sale pays now: his value, within the season's profit room. */
    public static function quickPays(object $player, int $clubId, ?array $room = null, ?array $bought = null): int
    {
        $room ??= self::room($clubId);

        return min((int) $player->value, self::basis($player, $bought) + self::leftFor($room, (int) $player->id));
    }

    /** The room left for this player: his own listing's ask does not count against him. */
    private static function leftFor(array $room, int $playerId): int
    {
        return $room['left'] + ($room['reserved'][$playerId] ?? 0);
    }

    /**
     * The profit room this club still has this season: the allowance, less the profit it made selling outside
     * already, less what its listings ask over their players' cost (reserved, by player).
     *
     * @return array{allowance: int, used: int, reserved: array<int, int>, left: int}
     */
    public static function room(int $clubId): array
    {
        $club = DB::table('clubs')->where('id', $clubId)->first(['league_id']);
        $allowance = intdiv(Economy::scale((int) $club->league_id) * (int) config('game.economy.sale_profit_bp_per_season'), 10000);
        $since = DB::table('seasons')->where('league_id', $club->league_id)->orderByDesc('number')->value('starts_at');
        $used = (int) DB::table('club_transactions')->where('club_id', $clubId)->where('type', 'sale_profit')
            ->when($since, fn ($q) => $q->where('created_at', '>=', $since))->sum('amount');
        $listed = DB::table('transfer_listings')->join('players', 'players.id', '=', 'transfer_listings.player_id')
            ->where('transfer_listings.club_id', $clubId)->get(['transfer_listings.price', 'players.id', 'players.club_id', 'players.value', 'players.base_value', 'players.bought_for']);
        $bought = $listed->isEmpty() ? [] : self::boughtIds($clubId);
        $reserved = $listed->mapWithKeys(fn ($l) => [(int) $l->id => max(0, (int) $l->price - self::basis($l, $bought))])->all();

        return ['allowance' => $allowance, 'used' => $used, 'reserved' => $reserved, 'left' => max(0, $allowance - $used - array_sum($reserved))];
    }

    /**
     * Post a sale outside the league: its cost back as $type, and what is over it as sale_profit (counted against
     * the room). Returns the balance after.
     */
    public static function post(int $clubId, string $type, int $price, int $basis, string $key, string $reference): int
    {
        $profit = max(0, $price - $basis);
        $balance = ClubLedger::post($clubId, $type, $price - $profit, $key, $reference);
        if ($profit > 0) {
            $balance = ClubLedger::post($clubId, 'sale_profit', $profit, "{$key}:profit", $reference);
        }

        return $balance;
    }

    /** The players of this club it bought before their price was kept (from the pool, a bot or another coach). */
    public static function boughtIds(int $clubId): array
    {
        $refs = DB::table('club_transactions')->where('club_id', $clubId)->whereIn('type', ['pool_buy', 'bot_buy'])->whereLike('reference', 'player:%')->pluck('reference')
            ->map(fn ($r) => (int) substr($r, 7));

        return array_flip($refs->merge(DB::table('player_moves')->where('to_club_id', $clubId)->pluck('player_id'))->map(fn ($id) => (int) $id)->all());
    }

    /** The least a listing may ask: the floor of a fair price between coaches, never above the cap. */
    public static function floor(object $player, ?int $cap = null): int
    {
        $floor = intdiv((int) $player->value * (int) config('game.economy.human_trade_min_bp'), 10000);

        return $cap === null ? $floor : min($floor, $cap);
    }

    /**
     * The wait (seconds) for this price, before the random part: longer the nearer the price is to the cap, moved by
     * the buyer's demand for his age and rating [Sprint 23]. A transfer madness shortens it later (effectiveAt).
     */
    public static function wait(int $price, int $value, int $leagueId, ?int $scale = null, ?int $age = null, ?int $overall = null): int
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
        $demand = intdiv(self::demand('demand_age', $age) * self::demand('demand_overall', $overall), 10000);

        return max(60, intdiv(intdiv($hours100 * 36 * $scale, 10000) * $demand, 10000));
    }

    /** The buyer's demand for this age or rating, as a share of the wait (bp); 10000 when not known. */
    public static function demand(string $table, ?int $x): int
    {
        if ($x === null) {
            return 10000;
        }
        $points = config("game.economy.virtual_buyer.{$table}");
        ksort($points);
        foreach ($points as $upTo => $bp) {
            if ($x <= $upTo) {
                return (int) $bp;
            }
        }

        return (int) end($points);
    }

    /** When a listing at this price sells: the wait, give or take jitter_bp. */
    public static function sellsAt(int $price, int $value, int $leagueId, ?int $age = null, ?int $overall = null): Carbon
    {
        $wait = self::wait($price, $value, $leagueId, null, $age, $overall);
        $jitter = (int) config('game.economy.virtual_buyer.jitter_bp');
        $wait = intdiv($wait * random_int(10000 - $jitter, 10000 + $jitter), 10000);

        return GameClock::now()->copy()->addSeconds(max(60, $wait));
    }

    /**
     * When this listing sells: its sells_at, or in a transfer madness its wait (from the listing) that many times
     * as short [Sprint 23], so listings made before the madness hurry too.
     */
    public static function effectiveAt(object $listing, int $times): Carbon
    {
        $at = Carbon::parse($listing->sells_at, 'UTC');
        if ($times <= 10000) {
            return $at;
        }
        $from = Carbon::parse($listing->updated_at ?? $listing->created_at, 'UTC');

        return $from->copy()->addSeconds(intdiv(max(0, (int) $from->diffInSeconds($at)) * 10000, $times));
    }

    /** Every minute: the listings whose time has come go to their buyer, while the market is open. */
    public static function due(): int
    {
        $n = 0;
        $listings = fn () => DB::table('transfer_listings')->join('clubs', 'clubs.id', '=', 'transfer_listings.club_id')
            ->whereNotNull('transfer_listings.sells_at')->select('transfer_listings.*', 'clubs.league_id', 'clubs.user_id');
        $due = $listings()->where('transfer_listings.sells_at', '<=', GameClock::now())->orderBy('transfer_listings.sells_at')->get();
        // A transfer madness: every listing of its leagues, by its shortened wait.
        $mad = collect(TimedEvents::runningOf(['madness']));
        if ($mad->isNotEmpty()) {
            $leagues = $mad->contains(fn ($e) => $e->league_id === null) ? null : $mad->pluck('league_id')->all();
            $due = $due->concat($listings()->where('transfer_listings.sells_at', '>', GameClock::now())
                ->when($leagues, fn ($q) => $q->whereIn('clubs.league_id', $leagues))->get()
                ->filter(fn ($l) => self::effectiveAt($l, TimedEvents::times('madness', (int) $l->league_id))->lte(GameClock::now())));
        }
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
            // What he brings over his cost counts against the season's room [Sprint 23].
            self::post((int) $l->club_id, 'listing_sale', (int) $l->price, self::basis($p), "listing:{$l->id}:{$p->id}", "player:{$p->id}");
            SellOn::settle((int) $l->club_id, (int) $p->id, (int) $l->price, "listing:{$l->id}:{$p->id}");   // [X62]
            Inbox::send($l->user_id ? (int) $l->user_id : null, 'listing_sold', ['player' => $p->name, 'price' => (int) $l->price,
                'league_id' => $l->league_id], (int) $l->league_id, (int) $l->club_id);

            return true;
        });
    }
}
