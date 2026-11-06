<?php

namespace App\Market;

use App\League\ClubLedger;
use App\League\ClubStrength;
use App\League\Integrity;
use App\League\MatchPrep;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Trades between coaches [PLAN 2.7, Sprint 25]. An offer names the other club's players the offering coach wants
 * ("in"), his own players he gives ("out") and his money; the other coach accepts, rejects or counters. Nothing
 * moves until it is accepted, and then all of it moves in one IMMEDIATE transaction: each player by a conditional
 * update checked by its rows, the money through ClubLedger. The limits against two accounts moving money between
 * them: what the buyer pays (money and his players' value) between 50% and 200% of what he gets, no player
 * twice between the same two clubs in a season, and what one club gives the other beyond value in a season
 * under a cap (25% of the starting budget).
 * An offer dies when one of its players leaves for anywhere else.
 */
class Transfers
{
    public const OPEN = ['pending'];

    /**
     * The coach lists one of his players at his price, from half his value to his sale cap [X6], up to max_listings
     * at a time [Sprint 23]. Other coaches may
     * buy him meanwhile; otherwise a buyer from outside the league takes him at that price when its time comes
     * (App\Market\Buyer): the dearer, the longer the wait. [X84] Once only: a player listed already is refused (the
     * owner's report 2026-11-02, the screens let him be listed again and again); a new price is withdraw, then list.
     */
    public static function list(int $clubId, int $playerId, int $price): void
    {
        Integrity::assertMarket($clubId);
        MatchPrep::assertFree([$playerId]);
        $p = DB::table('players')->where('id', $playerId)->where('club_id', $clubId)->first();
        abort_unless($p, 404, 'اللاعب ليس في فريقك.');
        $leagueId = (int) DB::table('clubs')->where('id', $clubId)->value('league_id');
        Market::assertOpen($leagueId);
        if (DB::table('transfer_listings')->where('player_id', $playerId)->exists()) {
            throw new HttpException(409, 'هذا اللاعب معروض للبيع بالفعل. اسحبه من قائمة الانتقالات أولاً إن أردت سعراً آخر.');
        }
        // [Sprint 23] At most max_listings players listed at a time.
        $max = (int) config('game.economy.max_listings');
        if (DB::table('transfer_listings')->where('club_id', $clubId)->count() >= $max) {
            throw new HttpException(422, sprintf(__('تعرض %d لاعبين الآن، وهذا أقصى ما يُعرض في نفس الوقت: اسحب أحدهم أو انتظر بيعه.'), $max));
        }
        // [X101] The players listed already count as gone: the line keeps its minimum even if all of them sell.
        Market::assertLineKeeps($clubId, (string) DB::table('master_players')->where('id', $p->master_player_id)->value('line'), 0, true);
        $cap = Buyer::cap($p, $clubId);
        $floor = Buyer::floor($p, $cap);
        if ($price < $floor || $price > $cap) {
            throw new HttpException(422, sprintf('سعر البيع من %s إلى سقف هذا اللاعب %s.', number_format($floor), number_format($cap)));
        }
        $m = DB::table('master_players')->where('id', $p->master_player_id)->first(['age']);
        // insertOrIgnore: two taps at once list him once (the row is unique by player).
        $listed = DB::table('transfer_listings')->insertOrIgnore(['club_id' => $clubId, 'player_id' => $playerId, 'price' => $price,
            'sells_at' => Buyer::sellsAt($price, (int) $p->value, $leagueId, (int) $m->age, (int) $p->overall + (int) $p->training_bonus),
            'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        if ($listed === 0) {
            throw new HttpException(409, 'هذا اللاعب معروض للبيع بالفعل. اسحبه من قائمة الانتقالات أولاً إن أردت سعراً آخر.');
        }
    }

    public static function unlist(int $clubId, int $playerId): void
    {
        DB::table('transfer_listings')->where('club_id', $clubId)->where('player_id', $playerId)->delete();
    }

    /**
     * A new offer from one coach's club to another's. $in: the other club's players wanted; $out: his own given.
     * Checked now (so the coach hears at once) and again when accepted.
     */
    public static function offer(int $fromClub, int $toClub, int $money, array $in, array $out, string $key, ?int $counterOf = null, int $sellOnBp = 0): int
    {
        Integrity::assertMarket($fromClub);

        if ($sellOnBp < 0 || $sellOnBp > (int) config('game.economy.sell_on_max_bp') || ($sellOnBp > 0 && ! $in)) {
            throw new HttpException(422, sprintf(__('نسبة البيع القادم من 0 إلى %d%%، وعلى لاعب تأخذه.'), intdiv((int) config('game.economy.sell_on_max_bp'), 100)));
        }

        return DB::transaction(function () use ($fromClub, $toClub, $money, $in, $out, $key, $counterOf, $sellOnBp) {
            $done = DB::table('transfer_offers')->where('idempotency_key', $key)->value('id');
            if ($done) {
                return (int) $done;
            }
            $from = DB::table('clubs')->where('id', $fromClub)->first();
            $to = DB::table('clubs')->where('id', $toClub)->first();
            abort_unless($to && $to->league_id === $from->league_id && $to->id !== $from->id, 404, 'النادي غير موجود في هذا الدوري.');
            abort_unless($to->user_id !== null, 409, 'هذا نادي حاسوب: اشترِ منه من السوق.');
            Market::assertOpen($from->league_id);
            $season = (int) DB::table('seasons')->where('league_id', $from->league_id)->orderByDesc('number')->value('id');
            self::check($from, $to, $season, $money, $in, $out);

            $now = GameClock::now();
            $id = DB::table('transfer_offers')->insertGetId([
                'league_id' => $from->league_id, 'season_id' => $season, 'from_club_id' => $fromClub, 'to_club_id' => $toClub,
                'money' => $money, 'status' => 'pending', 'counter_of' => $counterOf, 'idempotency_key' => $key, 'sell_on_bp' => $sellOnBp,
                'expires_at' => $now->copy()->addHours((int) config('game.economy.offer_hours')), 'created_at' => $now, 'updated_at' => $now,
            ]);
            DB::table('offer_items')->insert([
                ...array_map(fn ($p) => ['offer_id' => $id, 'player_id' => $p, 'direction' => 'in'], $in),
                ...array_map(fn ($p) => ['offer_id' => $id, 'player_id' => $p, 'direction' => 'out'], $out),
            ]);
            Inbox::send($to->user_id, $counterOf ? 'offer_countered' : 'offer_received', self::summary($id), $from->league_id, $toClub);

            return $id;
        });
    }

    /** The other coach takes it: everything moves now, or nothing. */
    public static function accept(int $offerId, int $byClub): void
    {
        Integrity::assertMarket($byClub);
        DB::transaction(function () use ($offerId, $byClub) {
            $o = self::pending($offerId, $byClub, 'to_club_id');
            $from = DB::table('clubs')->where('id', $o->from_club_id)->first();
            $to = DB::table('clubs')->where('id', $o->to_club_id)->first();
            Market::assertOpen($from->league_id);
            [$in, $out] = self::items($offerId);
            self::check($from, $to, (int) $o->season_id, (int) $o->money, $in, $out);
            $value = fn (array $ids) => (int) DB::table('players')->whereIn('id', $ids)->sum('value');
            $excess = (int) $o->money + $value($out) - $value($in);
            if (DB::table('transfer_offers')->where('id', $offerId)->where('status', 'pending')
                ->update(['status' => 'accepted', 'excess' => $excess, 'decided_at' => GameClock::now(), 'updated_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, 'تم البت في هذا العرض من قبل.');
            }
            $now = GameClock::now();
            foreach ([[$in, $to->id, $from->id], [$out, $from->id, $to->id]] as [$players, $was, $goes]) {
                foreach ($players as $p) {
                    // [Sprint 23] His cost to his new club: his value now (a trade's money is not split by player).
                    if (DB::table('players')->where('id', $p)->where('club_id', $was)->update(['club_id' => $goes, 'bought_for' => DB::raw('value'), 'updated_at' => $now]) !== 1) {
                        throw new HttpException(409, 'أحد لاعبي العرض لم يعد متاحاً.');
                    }
                }
            }
            ClubStrength::refresh((int) $from->id, (int) $to->id);   // [X98]
            if ($o->money > 0) {
                ClubLedger::post($from->id, 'transfer_buy', -(int) $o->money, "offer:{$offerId}:pay", "offer:{$offerId}", spend: true);
                ClubLedger::post($to->id, 'transfer_sale', (int) $o->money, "offer:{$offerId}:get", "offer:{$offerId}");
                // [X62] A clause on a player the seller had bought: its share of this money, split by the players' values.
                $total = max(1, $value($in));
                foreach ($in as $p) {
                    SellOn::settle($to->id, $p, intdiv((int) $o->money * (int) DB::table('players')->where('id', $p)->value('value'), $total), "offer:{$offerId}:{$p}");
                }
            }
            // [X62] And this deal's own clause, on the players the buyer took.
            SellOn::promise($in, $to->id, (int) ($o->sell_on_bp ?? 0));
            // The money goes with the first player the payer receives (the pair cap reads the moves).
            $first = true;
            foreach ([[$in, $to->id, $from->id], [$out, $from->id, $to->id]] as [$players, $was, $goes]) {
                foreach ($players as $p) {
                    DB::table('player_moves')->insert(['season_id' => $o->season_id, 'player_id' => $p, 'from_club_id' => $was, 'to_club_id' => $goes,
                        'price' => $first && $goes === $from->id ? (int) $o->money : 0, 'offer_id' => $offerId, 'created_at' => $now]);
                    $first = $first && $goes !== $from->id;
                    self::left($p, $was, $offerId);
                }
            }
            Inbox::send($from->user_id, 'offer_accepted', self::summary($offerId), $from->league_id, $from->id);
        });
    }

    /** The other coach says no. */
    public static function reject(int $offerId, int $byClub): void
    {
        $o = self::pending($offerId, $byClub, 'to_club_id');
        self::close($o, 'rejected', 'offer_rejected');
    }

    /** The one who offered takes it back. */
    public static function cancel(int $offerId, int $byClub): void
    {
        $o = self::pending($offerId, $byClub, 'from_club_id');
        self::close($o, 'cancelled', null);
    }

    /** The other coach answers with his own terms: a new offer the other way, and this one is closed. */
    public static function counter(int $offerId, int $byClub, int $money, array $in, array $out, string $key): int
    {
        return DB::transaction(function () use ($offerId, $byClub, $money, $in, $out, $key) {
            $o = self::pending($offerId, $byClub, 'to_club_id');
            DB::table('transfer_offers')->where('id', $offerId)->where('status', 'pending')
                ->update(['status' => 'countered', 'decided_at' => GameClock::now(), 'updated_at' => GameClock::now()]);

            return self::offer($byClub, (int) $o->from_club_id, $money, $in, $out, $key, $offerId);
        });
    }

    /**
     * A player left his club (to anyone): his listing goes, and every open offer that names him dies, its
     * coaches told. $except: the offer that moved him.
     */
    public static function left(int $playerId, ?int $fromClub = null, ?int $except = null): void
    {
        DB::table('transfer_listings')->where('player_id', $playerId)->delete();
        $offers = DB::table('transfer_offers')->join('offer_items', 'offer_items.offer_id', '=', 'transfer_offers.id')
            ->where('offer_items.player_id', $playerId)->where('transfer_offers.status', 'pending')
            ->when($except, fn ($q) => $q->where('transfer_offers.id', '!=', $except))->select('transfer_offers.*')->distinct()->get();
        foreach ($offers as $o) {
            self::close($o, 'cancelled', 'offer_cancelled');
        }
        if ($fromClub) {
            ClubStrength::refresh($fromClub);   // [X98] the squad he left
            DB::table('lineup_slots')->whereIn('lineup_id', DB::table('lineups')->where('club_id', $fromClub)->select('id'))->where('player_id', $playerId)->delete();
            foreach (['captain_id', 'penalty_id', 'free_kick_id', 'corner_id'] as $col) {
                DB::table('set_piece_takers')->where('club_id', $fromClub)->where($col, $playerId)->update([$col => null]);
            }
        }
    }

    /** Every minute: open offers past their time expire. */
    public static function expire(): int
    {
        $n = 0;
        foreach (DB::table('transfer_offers')->where('status', 'pending')->where('expires_at', '<=', GameClock::now())->get() as $o) {
            $n += self::close($o, 'expired', 'offer_expired') ? 1 : 0;
        }

        return $n;
    }

    /** Every limit, before an offer is made and again when it is accepted. */
    private static function check(object $from, object $to, int $seasonId, int $money, array $in, array $out): void
    {
        // Nobody in a sheet locked for a match changes club before it ends [X31].
        MatchPrep::assertFree([...$in, ...$out]);
        if (! $in) {
            throw new HttpException(422, 'اختر لاعباً واحداً على الأقل من فريق الطرف الآخر.');
        }
        if (array_intersect($in, $out) || count(array_unique($in)) !== count($in) || count(array_unique($out)) !== count($out)) {
            throw new HttpException(422, 'لاعب مكرر في العرض.');
        }
        $theirs = DB::table('players')->whereIn('id', $in)->where('club_id', $to->id)->get();
        $mine = DB::table('players')->whereIn('id', $out)->where('club_id', $from->id)->get();
        if ($theirs->count() !== count($in) || $mine->count() !== count($out)) {
            throw new HttpException(409, 'أحد لاعبي العرض لم يعد متاحاً.');
        }
        // 1. A fair price: what the buyer pays (money and his players) against what he gets.
        self::assertFair($money + (int) $mine->sum('value'), (int) $theirs->sum('value'));
        // 2. No player twice between the same two clubs this season.
        $pair = fn ($q) => $q->where(fn ($q) => $q->where('from_club_id', $from->id)->where('to_club_id', $to->id))
            ->orWhere(fn ($q) => $q->where('from_club_id', $to->id)->where('to_club_id', $from->id));
        $again = DB::table('player_moves')->where('season_id', $seasonId)->whereIn('player_id', [...$in, ...$out])->where($pair)
            ->groupBy('player_id')->havingRaw('count(*) >= ?', [(int) config('game.economy.same_pair_player_moves_per_season')])->pluck('player_id');
        if ($again->isNotEmpty()) {
            throw new HttpException(409, 'انتقل هذا اللاعب بين الناديين هذا الموسم، فلا ينتقل بينهما مرة أخرى.');
        }
        // 3. What one club gave the other beyond value, this season, stays under the cap: two accounts cannot pour
        //    money from one club into the other by overpaying, while fair trades move whatever money they need.
        $excess = fn ($a, $b) => (int) DB::table('transfer_offers')->where('season_id', $seasonId)->where('status', 'accepted')
            ->where('from_club_id', $a)->where('to_club_id', $b)->sum('excess');
        $this_ = $money + (int) $mine->sum('value') - (int) $theirs->sum('value');
        $net = $excess($from->id, $to->id) - $excess($to->id, $from->id) + $this_;
        $budget = (int) DB::table('leagues')->where('id', $from->league_id)->value('starting_budget');
        $cap = intdiv($budget * (int) config('game.economy.pair_net_transfer_cap_bp'), 10000);
        if (abs($net) > $cap) {
            throw new HttpException(409, sprintf('تجاوز سقف ما يُدفع فوق القيمة بين الناديين هذا الموسم (%s). المتبقي %s.', number_format($cap), number_format(max(0, $cap - abs($net - $this_)))));
        }
        // 4. Each side keeps a squad.
        foreach ([[$from->id, count($in) - count($out)], [$to->id, count($out) - count($in)]] as [$club, $change]) {
            if ($change < 0 && DB::table('players')->where('club_id', $club)->count() + $change < (int) config('game.economy.min_squad')) {
                throw new HttpException(409, 'لا يمكن أن ينزل أي فريق عن 16 لاعباً.');
            }
        }
        // [X101] And each line its minimum: what a club gives of a line, less what it gets of it.
        $lines = fn ($ids) => DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.id', $ids)->pluck('master_players.line')->countBy();
        [$gets, $gives] = [$lines($in), $lines($out)];
        foreach ([[$from->id, $gives, $gets], [$to->id, $gets, $gives]] as [$club, $leaving, $coming]) {
            foreach ($leaving as $line => $n) {
                $net = $n - ($coming[$line] ?? 0);
                if ($net > 0) {
                    Market::assertLineKeeps($club, (string) $line, $net - 1);
                }
            }
        }
        // 5. The buyer can pay.
        if ($money > 0 && (int) $from->balance < $money) {
            throw new HttpException(409, 'رصيد النادي لا يكفي.');
        }
    }

    /** Between 50% and 200% of the value [PLAN 2.7]. */
    private static function assertFair(int $price, int $value): void
    {
        $cfg = config('game.economy');
        $min = intdiv($value * $cfg['human_trade_min_bp'], 10000);
        $max = intdiv($value * $cfg['human_trade_max_bp'], 10000);
        if ($price < $min || $price > $max) {
            throw new HttpException(422, sprintf('السعر بين المدربين من 50%% إلى 200%% من القيمة: بين %s و%s.', number_format($min), number_format($max)));
        }
    }

    private static function pending(int $offerId, int $clubId, string $side): object
    {
        $o = DB::table('transfer_offers')->where('id', $offerId)->first();
        abort_unless($o && (int) $o->{$side} === $clubId, 404, 'العرض غير موجود.');
        if ($o->status !== 'pending') {
            throw new HttpException(409, 'تم البت في هذا العرض من قبل.');
        }
        if (GameClock::now()->gte($o->expires_at)) {
            self::close($o, 'expired', 'offer_expired');
            throw new HttpException(409, 'انتهت مدة هذا العرض.');
        }

        return $o;
    }

    private static function close(object $o, string $status, ?string $message): bool
    {
        $closed = DB::table('transfer_offers')->where('id', $o->id)->where('status', 'pending')
            ->update(['status' => $status, 'decided_at' => GameClock::now(), 'updated_at' => GameClock::now()]) === 1;
        if ($closed && $message) {
            $user = DB::table('clubs')->where('id', $o->from_club_id)->value('user_id');
            Inbox::send($user, $message, self::summary($o->id), $o->league_id, $o->from_club_id);
            if ($status === 'cancelled' || $status === 'expired') {
                Inbox::send(DB::table('clubs')->where('id', $o->to_club_id)->value('user_id'), $message, self::summary($o->id), $o->league_id, $o->to_club_id);
            }
        }

        return $closed;
    }

    /** @return array{0: list<int>, 1: list<int>} */
    public static function items(int $offerId): array
    {
        $rows = DB::table('offer_items')->where('offer_id', $offerId)->orderBy('id')->get();

        return [$rows->where('direction', 'in')->pluck('player_id')->map(fn ($i) => (int) $i)->values()->all(),
            $rows->where('direction', 'out')->pluck('player_id')->map(fn ($i) => (int) $i)->values()->all()];
    }

    /** What a message about the offer says: who, which players, how much. */
    private static function summary(int $offerId): array
    {
        $o = DB::table('transfer_offers')->where('id', $offerId)->first();
        $names = fn (string $dir) => DB::table('offer_items')->join('players', 'players.id', '=', 'offer_items.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('offer_id', $offerId)->where('direction', $dir)->pluck('master_players.name')->all();

        return ['offer_id' => $offerId, 'from' => DB::table('clubs')->where('id', $o->from_club_id)->value('name'),
            'to' => DB::table('clubs')->where('id', $o->to_club_id)->value('name'), 'money' => (int) $o->money,
            'in' => $names('in'), 'out' => $names('out')];
    }
}
