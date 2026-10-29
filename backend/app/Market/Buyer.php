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
 * Selling a player [X6, 2026-10-24]. Every player has a sale cap: 250% of his value [Sprint 23], or his value alone
 * when the club bought him (so buying and selling on never makes money from nothing; his training gains still
 * count, since training raises his value). A coach lists up to max_listings players at any price from half the
 * value to the cap, and a buyer from outside the league takes each at that price after a wait: an hour at half
 * his value, six at his value, eight days at the cap, moved by his age and rating (the buyer's demand), scaled by
 * the season's length, a little random, and shorter in a transfer madness. Every listed player is sold in the
 * end; another coach may still buy him first. What the outside buyers pay a club above the value in a season is
 * capped (outside_premium_bp_per_season of the league's money scale), so the cap shrinks once it is spent.
 */
class Buyer
{
    /** The most a player listed by this club may ask: within the season's room above the value too. */
    public static function cap(object $player, int $clubId, ?bool $bought = null, ?array $room = null): int
    {
        $bought ??= DB::table('club_transactions')->where('club_id', $clubId)->where('reference', "player:{$player->id}")
            ->whereIn('type', ['pool_buy', 'bot_buy'])->exists()
            || DB::table('player_moves')->where('player_id', $player->id)->where('to_club_id', $clubId)->exists();
        $value = (int) $player->value;
        if ($bought) {
            return $value;
        }
        $room ??= self::room($clubId);
        // His own listing's ask does not count against him.
        $left = $room['left'] + ($room['reserved'][$player->id] ?? 0);

        return max($value, min(intdiv($value * (int) config('game.economy.sale_cap_bp'), 10000), $value + $left));
    }

    /**
     * The room above the value outside buyers may still pay this club this season: the allowance, less what they
     * paid above it already, less what its listings ask above it (reserved, by player).
     *
     * @return array{allowance: int, used: int, reserved: array<int, int>, left: int}
     */
    public static function room(int $clubId): array
    {
        $club = DB::table('clubs')->where('id', $clubId)->first(['league_id']);
        $allowance = intdiv(Economy::scale((int) $club->league_id) * (int) config('game.economy.outside_premium_bp_per_season'), 10000);
        $since = DB::table('seasons')->where('league_id', $club->league_id)->orderByDesc('number')->value('starts_at');
        $used = (int) DB::table('club_transactions')->where('club_id', $clubId)->where('type', 'listing_premium')
            ->when($since, fn ($q) => $q->where('created_at', '>=', $since))->sum('amount');
        $reserved = DB::table('transfer_listings')->join('players', 'players.id', '=', 'transfer_listings.player_id')
            ->where('transfer_listings.club_id', $clubId)->get(['transfer_listings.player_id', 'transfer_listings.price', 'players.value'])
            ->mapWithKeys(fn ($l) => [(int) $l->player_id => max(0, (int) $l->price - (int) $l->value)])->all();

        return ['allowance' => $allowance, 'used' => $used, 'reserved' => $reserved, 'left' => max(0, $allowance - $used - array_sum($reserved))];
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
            // What he brings above his value counts against the season's room [Sprint 23].
            $premium = max(0, (int) $l->price - (int) $p->value);
            ClubLedger::post((int) $l->club_id, 'listing_sale', (int) $l->price - $premium, "listing:{$l->id}:{$p->id}", "player:{$p->id}");
            if ($premium > 0) {
                ClubLedger::post((int) $l->club_id, 'listing_premium', $premium, "listing:{$l->id}:{$p->id}:premium", "player:{$p->id}");
            }
            Inbox::send($l->user_id ? (int) $l->user_id : null, 'listing_sold', ['player' => $p->name, 'price' => (int) $l->price,
                'league_id' => $l->league_id], (int) $l->league_id, (int) $l->club_id);

            return true;
        });
    }
}
