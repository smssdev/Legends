<?php

namespace App\Market;

use App\League\ClubLedger;
use App\League\Integrity;
use App\League\MatchPrep;
use App\Support\GameClock;
use App\Wallet\Price;
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
    /** The market is open from the league's creation until the lock round. Null when open, or why it is closed. */
    public static function closed(int $leagueId): ?string
    {
        $season = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->first();
        if (! $season || $season->status === 'finished') {
            return 'انتهى الموسم، والسوق مغلق حتى الموسم الجديد.';
        }
        if ($season->rounds_played + 1 >= $season->lock_from_round) {
            return 'السوق مغلق في آخر ربع من الموسم.';
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

            return $player->in_pool || $scouted ? intdiv((int) $player->value * $cfg['buy_from_pool_bp'], 10000) : null;
        }
        $bot = DB::table('clubs')->where('id', $player->club_id)->whereNull('user_id')->exists();

        return $bot ? intdiv((int) $player->value * $cfg['buy_from_bot_bp'], 10000) : null;
    }

    /** Buy a player from the pool or from a bot club. Returns the buyer's balance after. */
    public static function buy(int $clubId, int $playerId, string $key): int
    {
        Integrity::assertMarket($clubId);

        return DB::transaction(function () use ($clubId, $playerId, $key) {
            $done = DB::table('club_transactions')->where('idempotency_key', $key)->first();
            if ($done) {
                return (int) $done->balance_after;
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            self::assertOpen($club->league_id);
            $p = DB::table('players')->where('id', $playerId)->where('league_id', $club->league_id)->first();
            abort_unless($p, 404, 'اللاعب غير موجود في هذا الدوري.');
            if ($p->club_id === $clubId) {
                throw new HttpException(409, 'اللاعب في فريقك بالفعل.');
            }
            if ($p->club_id !== null && DB::table('clubs')->where('id', $p->club_id)->whereNotNull('user_id')->exists()) {
                throw new HttpException(409, 'اللاعب في فريق مدرب آخر.');
            }
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
                ->update(['club_id' => $clubId, 'in_pool' => false, 'scouted_by' => null, 'updated_at' => GameClock::now()]);
            if ($taken !== 1) {
                throw new HttpException(409, 'سبقك مدرب آخر إلى هذا اللاعب.');
            }
            $balance = ClubLedger::post($clubId, $from === null ? 'pool_buy' : 'bot_buy', -$price, $key, "player:{$playerId}", spend: true);
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
            $done = DB::table('club_transactions')->where('idempotency_key', $key)->first();
            if ($done) {
                return (int) $done->balance_after;
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            self::assertOpen($club->league_id);
            $p = DB::table('players')->where('id', $playerId)->where('club_id', $clubId)->first();
            abort_unless($p, 404, 'اللاعب ليس في فريقك.');
            self::assertKeeps($clubId, $p, (int) config('game.economy.min_squad'), 'لا يمكن أن ينزل فريقك عن %d لاعباً.');
            $fee = intdiv((int) $p->value * (int) config('game.economy.quick_sale_fee_bp'), 10000);
            Price::charge($clubId, 'quick_sale', $fee, "{$key}:fee", "player:{$playerId}");
            $sold = DB::table('players')->where('id', $playerId)->where('club_id', $clubId)->update(['club_id' => null, 'in_pool' => true, 'updated_at' => GameClock::now()]);
            if ($sold !== 1) {
                throw new HttpException(409, 'اللاعب لم يعد في فريقك.');
            }
            Transfers::left($playerId, $clubId);

            return ClubLedger::post($clubId, 'pool_sale', (int) $p->value, $key, "player:{$playerId}");
        });
    }

    /** A bot keeps 18 players and 2 keepers [PLAN 2.7]. */
    private static function assertBotCanSell(int $botId, object $player): void
    {
        abort_unless(DB::table('clubs')->where('id', $botId)->whereNull('user_id')->exists(), 409, 'هذا اللاعب ليس للبيع هنا.');
        self::assertKeeps($botId, $player, (int) config('game.economy.bot_min_squad'), 'نادي الحاسوب لا يبيع إن نزل عن %d لاعباً.');
    }

    private static function assertKeeps(int $clubId, object $player, int $min, string $message): void
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
