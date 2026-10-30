<?php

namespace App\Market;

use App\Economy\Contracts;
use App\League\ClubLedger;
use App\League\Integrity;
use App\League\MatchPrep;
use App\Support\GameClock;
use App\TimedEvents\TimedEvents;
use App\Wallet\Price;
use App\Wallet\Wallet;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The market with the pool and the bot clubs [PLAN 2.4, 2.7, Sprint 24]. Open all season until its last 25%
 * (the lock). The pool sells at 100% of a player's value and buys at 70% of his value without training; a bot
 * club sells at a fixed 125%, never below 18 players or 2 keepers, and never sells on its own. A coach sells to the
 * pool at once at the full value for a few coins, or lists the player and waits for a buyer [X6]. A player is
 * taken by one conditional update checked by its rows, and the money moves in the same IMMEDIATE transaction,
 * so of two coaches buying the same player at the same moment one gets him and the other pays nothing.
 */
class Market
{
    /**
     * [UP11] The transfers made in the league this season, newest first: from the world (the pool), from the
     * computer's clubs, and between coaches.
     *
     * @return list<array{player: string, from: ?string, to: string, price: int, at: string}>
     */
    public static function history(int $leagueId, int $limit = 60): array
    {
        $clubs = DB::table('clubs')->where('league_id', $leagueId)->pluck('name', 'id');
        $name = fn (int $playerId) => DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.id', $playerId)->value('master_players.name');
        $market = DB::table('club_transactions')->whereIn('club_id', $clubs->keys())->whereIn('type', ['pool_buy', 'bot_buy'])->orderByDesc('id')->limit($limit)->get()
            ->map(function ($t) use ($clubs, $name) {
                $player = (int) substr((string) $t->reference, 7);
                $seller = $t->type === 'bot_buy' ? DB::table('club_transactions')->where('idempotency_key', $t->idempotency_key.':seller')->value('club_id') : null;

                return ['player' => $name($player), 'from' => $seller ? $clubs[$seller] ?? null : null, 'to' => $clubs[$t->club_id], 'price' => (int) $t->amount * -1 + 0,
                    'at' => Carbon::parse($t->created_at, 'UTC')->toIso8601ZuluString()];
            });
        $season = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->value('id');
        $coaches = DB::table('player_moves')->where('season_id', $season)->orderByDesc('id')->limit($limit)->get()
            ->map(fn ($m) => ['player' => $name((int) $m->player_id), 'from' => $m->from_club_id ? $clubs[$m->from_club_id] ?? null : null,
                'to' => $m->to_club_id ? $clubs[$m->to_club_id] ?? '' : '', 'price' => (int) $m->price,
                'at' => Carbon::parse($m->created_at, 'UTC')->toIso8601ZuluString()]);

        return $market->concat($coaches)->sortByDesc('at')->take($limit)->values()->all();
    }

    /** The market is open from the league's creation until the lock round. Null when open, or why it is closed. */
    public static function closed(int $leagueId): ?string
    {
        $season = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->first();
        // [Sprint 29] A tournament plays with the squads it was drawn with: no market.
        if (DB::table('leagues')->where('id', $leagueId)->value('kind') === 'tournament') {
            return __('لا سوق في البطولات: كل فريق يلعب بقائمته.');
        }
        if (! $season || $season->status === 'finished') {
            return __('انتهى الموسم، والسوق مغلق حتى الموسم الجديد.');
        }
        if ($season->rounds_played + 1 >= $season->lock_from_round) {
            return __('السوق مغلق في آخر ربع من الموسم.');
        }

        return null;
    }

    public static function assertOpen(int $leagueId): void
    {
        if ($why = self::closed($leagueId)) {
            throw new HttpException(409, $why);
        }
    }

    /** What a player costs this club now: the pool's price (a scout's find too, for its club), or a bot's fixed one. Null when not for sale. */
    public static function price(object $player, ?int $buyer = null): ?int
    {
        $cfg = config('game.economy');
        if ($player->club_id === null) {
            $scouted = $buyer !== null && ($player->scouted_by ?? null) === $buyer;

            return $player->in_pool || $scouted ? self::poolPrice($player) : null;
        }
        $bot = DB::table('clubs')->where('id', $player->club_id)->whereNull('user_id')->exists();

        return $bot ? intdiv((int) $player->value * $cfg['buy_from_bot_bp'], 10000) : null;
    }

    /**
     * A world player's price [Sprint 23]: 100% of his value, a special offer's or a legend's own share of it, and a
     * market discount from the admin on the plain ones (the specials have their own price).
     */
    public static function poolPrice(object $player): int
    {
        if (($player->pool_price_bp ?? null) !== null) {
            return intdiv((int) $player->value * (int) $player->pool_price_bp, 10000);
        }
        $price = intdiv((int) $player->value * (int) config('game.economy.buy_from_pool_bp'), 10000);
        $off = TimedEvents::power('discount', (int) $player->league_id);

        return $off > 0 ? intdiv($price * (10000 - min(9000, $off)), 10000) : $price;
    }

    /**
     * [UP11] What buying this player takes from this club: the price, the coins to register the deal, and when its
     * cash is short but at least half the price, the cash it has and the coins for the rest. can is false (with
     * why) when it may not buy him that way.
     *
     * @return array{price: int, cash: int, doc_coins: int, short: int, compensate: ?array{cash: int, coins: int}, can: bool, why: ?string}
     */
    public static function quote(int $clubId, int $price): array
    {
        $cfg = config('game.economy');
        $club = DB::table('clubs')->where('id', $clubId)->first();
        $fair = (bool) DB::table('leagues')->where('id', $club->league_id)->value('fair_league');
        $cash = max(0, (int) $club->balance);
        $doc = $fair ? 0 : ($price >= $cfg['doc_big_from'] ? (int) $cfg['transfer_doc_coins_big'] : (int) $cfg['transfer_doc_coins']);
        $short = max(0, $price - $cash);
        $enough = $cash * 10000 >= $price * (int) $cfg['compensate_min_bp'];
        $compensate = $short > 0 && $enough && ! $fair ? ['cash' => $cash, 'coins' => intdiv($short + $cfg['money_per_coin'] - 1, $cfg['money_per_coin'])] : null;
        $why = match (true) {
            $short === 0 => null,
            ! $enough => __('أموال ناديك غير كافية، يلزم توفر 50% على الأقل من قيمة اللاعب نقداً.'),
            $fair => __('الدوري نزيه: لا تكمل الكوينز ما ينقص من المال.'),
            default => null,
        };

        return ['price' => $price, 'cash' => $cash, 'doc_coins' => $doc, 'short' => $short, 'compensate' => $compensate, 'can' => $why === null, 'why' => $why];
    }

    /**
     * Buy a player from the pool or from a bot club. Returns the buyer's balance after. [UP11] The coach pays the
     * deal's registration in coins; with $compensate and a short club (half the price at least in cash), all its
     * cash goes and the coins pay the rest.
     */
    public static function buy(int $clubId, int $playerId, string $key, bool $compensate = false): int
    {
        Integrity::assertMarket($clubId);

        return DB::transaction(function () use ($clubId, $playerId, $key, $compensate) {
            $done = DB::table('club_transactions')->where('idempotency_key', $key)->first();
            if ($done) {
                return (int) $done->balance_after;
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            self::assertOpen($club->league_id);
            $p = DB::table('players')->where('id', $playerId)->where('league_id', $club->league_id)->first();
            abort_unless($p, 404, __('اللاعب غير موجود في هذا الدوري.'));
            if ($p->club_id === $clubId) {
                throw new HttpException(409, 'اللاعب في فريقك بالفعل.');
            }
            if ($p->club_id !== null && DB::table('clubs')->where('id', $p->club_id)->whereNotNull('user_id')->exists()) {
                throw new HttpException(409, 'اللاعب في فريق مدرب آخر.');
            }
            // [X61 E1] The wage cap.
            Contracts::assertRoom($clubId, (int) $p->value);
            $price = self::price($p, $clubId);
            if ($price === null) {
                throw new HttpException(409, 'هذا اللاعب ليس للبيع هنا.');
            }
            $from = $p->club_id;
            if ($from !== null) {
                self::assertBotCanSell((int) $from, $p);
            }
            // The player is this buyer's only if nobody took him first.
            $taken = DB::table('players')->where('id', $playerId)
                ->where(fn ($q) => $from === null ? $q->whereNull('club_id')->where(fn ($q) => $q->where('in_pool', true)->orWhere('scouted_by', $clubId)) : $q->where('club_id', $from))
                ->update(['club_id' => $clubId, 'in_pool' => false, 'scouted_by' => null, 'pool_kind' => null, 'pool_price_bp' => null, 'bought_for' => $price, 'updated_at' => GameClock::now()]);
            if ($taken !== 1) {
                throw new HttpException(409, 'سبقك مدرب آخر إلى هذا اللاعب.');
            }
            $q = self::quote($clubId, $price);
            if ($q['short'] > 0 && (! $compensate || ! $q['can'] || ! $q['compensate'])) {
                throw new HttpException(409, $q['why'] ?? __('رصيد النادي لا يكفي: أكمل الباقي بالكوينز.'));
            }
            $paid = $q['short'] > 0 ? $q['cash'] : $price;
            $balance = ClubLedger::post($clubId, $from === null ? 'pool_buy' : 'bot_buy', -$paid, $key, "player:{$playerId}", spend: true);
            $user = (int) $club->user_id;
            if ($q['doc_coins'] > 0) {
                Wallet::pay($user, $club->league_id, 'transfer_doc', $q['doc_coins'], "doc:{$key}", "player:{$playerId}");
            }
            if ($q['short'] > 0) {
                Wallet::pay($user, $club->league_id, 'transfer_coins', $q['compensate']['coins'], "comp:{$key}", "player:{$playerId}");
            }
            if ($from !== null) {
                ClubLedger::post((int) $from, 'bot_sale', $price, "{$key}:seller", "player:{$playerId}");
                Transfers::left($playerId, (int) $from);
            }

            return $balance;
        });
    }

    /**
     * The instant sale [X6, 2026-10-24]: the player goes to the pool now at his full value (his training counted),
     * for game.premium.price.quick_sale coins from the coach's wallet (in a fair league, quick_sale_fee_bp of his
     * value from the club). Listing him instead (Transfers::list) costs nothing but waits for a buyer. Returns the
     * balance after.
     */
    public static function sell(int $clubId, int $playerId, string $key): int
    {
        Integrity::assertMarket($clubId);
        MatchPrep::assertFree([$playerId]);

        return DB::transaction(function () use ($clubId, $playerId, $key) {
            // Done already: the balance after its last line (the profit's, when it made one) [Sprint 23].
            $done = DB::table('club_transactions')->whereIn('idempotency_key', [$key, "{$key}:profit"])->orderByDesc('id')->first();
            if ($done) {
                return (int) $done->balance_after;
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            self::assertOpen($club->league_id);
            $p = DB::table('players')->where('id', $playerId)->where('club_id', $clubId)->first();
            abort_unless($p, 404, __('اللاعب ليس في فريقك.'));
            self::assertKeeps($clubId, $p, (int) config('game.economy.min_squad'), __('لا يمكن أن ينزل فريقك عن %d لاعباً.'));
            // [Sprint 23] His value, within the season's profit room.
            $pays = Buyer::quickPays($p, $clubId);
            $fee = intdiv((int) $p->value * (int) config('game.economy.quick_sale_fee_bp'), 10000);
            Price::charge($clubId, 'quick_sale', $fee, "{$key}:fee", "player:{$playerId}");
            $sold = DB::table('players')->where('id', $playerId)->where('club_id', $clubId)->update(['club_id' => null, 'in_pool' => true, 'updated_at' => GameClock::now()]);
            if ($sold !== 1) {
                throw new HttpException(409, 'اللاعب لم يعد في فريقك.');
            }
            Transfers::left($playerId, $clubId);

            $balance = Buyer::post($clubId, 'pool_sale', $pays, Buyer::basis($p), $key, "player:{$playerId}");

            return SellOn::settle($clubId, $playerId, $pays, $key) ? ClubLedger::sum($clubId) : $balance;   // [X62]
        });
    }

    /** A bot keeps 18 players and 2 keepers [PLAN 2.7]. */
    private static function assertBotCanSell(int $botId, object $player): void
    {
        abort_unless(DB::table('clubs')->where('id', $botId)->whereNull('user_id')->exists(), 409, __('هذا اللاعب ليس للبيع هنا.'));
        self::assertKeeps($botId, $player, (int) config('game.economy.bot_min_squad'), __('نادي الحاسوب لا يبيع إن نزل عن %d لاعباً.'));
    }

    public static function assertKeeps(int $clubId, object $player, int $min, string $message): void
    {
        $count = DB::table('players')->where('club_id', $clubId)->count();
        if ($count - 1 < $min) {
            throw new HttpException(409, sprintf($message, $min));
        }
        $line = DB::table('master_players')->where('id', $player->master_player_id)->value('line');
        $keepers = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $clubId)->where('master_players.line', 'gk')->count();
        if ($line === 'gk' && $keepers - 1 < (int) config('game.economy.min_keepers')) {
            throw new HttpException(409, 'لا بد أن يبقى حارسان على الأقل.');
        }
    }

    /**
     * A bot short of players (a forced sale) buys from the pool what it lacks [PLAN 2.7]: the cheapest keeper
     * first if it has fewer than two, then the cheapest players, while its money lasts.
     */
    public static function refill(int $clubId): int
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        if ($club->user_id !== null || self::closed($club->league_id)) {
            return 0;
        }
        $bought = 0;
        for ($i = 0; $i < 10; $i++) {
            $count = DB::table('players')->where('club_id', $clubId)->count();
            $keepers = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->where('players.club_id', $clubId)->where('master_players.line', 'gk')->count();
            $needKeeper = $keepers < (int) config('game.economy.min_keepers');
            if (! $needKeeper && $count >= (int) config('game.economy.bot_min_squad')) {
                break;
            }
            $balance = (int) DB::table('clubs')->where('id', $clubId)->value('balance');
            $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->where('players.league_id', $club->league_id)->whereNull('players.club_id')->where('players.in_pool', true)
                ->when($needKeeper, fn ($q) => $q->where('master_players.line', 'gk'))
                ->where('players.value', '<=', $balance)->orderBy('players.value')->orderBy('players.id')->select('players.id')->first();
            if (! $p) {
                break;
            }
            try {
                self::buy($clubId, $p->id, "refill:{$clubId}:{$p->id}:".GameClock::nowMs());
                $bought++;
            } catch (HttpException) {
                break;
            }
        }

        return $bought;
    }
}
