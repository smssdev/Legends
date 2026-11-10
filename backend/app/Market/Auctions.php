<?php

namespace App\Market;

use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Throwable;

/**
 * [Sprint 50 M18, the owner's decision 2026-11-10 in place of "no live bidding" (2026-11-01)] Timed auctions.
 * A coach lists a player as an auction (Transfers::list with minutes from game.auctions.minutes): his price is the
 * opening bid, and no outside buyer takes him (sells_at stays empty). The league's other coaches bid, each bid at
 * least the top one and a step; a bid in the last extend_seconds moves the end that far, so nobody wins in the last
 * second. When it ends the highest bid that can still be paid becomes a deal through the coaches' own transfer path
 * (Transfers::offer, then accept for the seller): the same checks, the same ledger, nothing held in between. A bid
 * that fails then (the bidder's money spent meanwhile, a cap reached) gives way to the next one.
 */
class Auctions
{
    /** The auctions open in a league, the soonest ending first, with the viewer's club's place in each. */
    public static function of(int $leagueId, ?int $clubId = null): array
    {
        $rows = DB::table('transfer_listings')->join('clubs', 'clubs.id', '=', 'transfer_listings.club_id')
            ->join('players', 'players.id', '=', 'transfer_listings.player_id')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('clubs.league_id', $leagueId)->whereNotNull('transfer_listings.auction_ends_at')
            ->orderBy('transfer_listings.auction_ends_at')
            ->get(['transfer_listings.player_id', 'transfer_listings.price', 'transfer_listings.auction_ends_at', 'transfer_listings.club_id',
                'clubs.name as club', 'master_players.name', 'master_players.position', 'master_players.age', 'players.overall', 'players.training_bonus', 'players.value']);

        return $rows->map(function ($r) use ($clubId) {
            $top = self::top((int) $r->player_id);
            $mine = $clubId ? (int) DB::table('auction_bids')->where('player_id', $r->player_id)->where('club_id', $clubId)->max('amount') : 0;

            return ['player_id' => (int) $r->player_id, 'name' => $r->name, 'position' => $r->position, 'age' => (int) $r->age,
                'overall' => (int) $r->overall + (int) $r->training_bonus, 'value' => (int) $r->value,
                'club_id' => (int) $r->club_id, 'club' => $r->club, 'opening' => (int) $r->price,
                'top' => $top ? (int) $top->amount : null, 'bids' => DB::table('auction_bids')->where('player_id', $r->player_id)->count(),
                'next' => self::next((int) $r->price, $top ? (int) $top->amount : null, (int) $r->value),
                'max' => intdiv((int) $r->value * (int) config('game.economy.human_trade_max_bp'), 10000),
                'mine' => $mine ?: null, 'leading' => $top && $clubId && (int) $top->club_id === $clubId,
                'ends_at' => Carbon::parse($r->auction_ends_at, 'UTC')->toIso8601ZuluString()];
        })->values()->all();
    }

    /** The least the next bid may be: the opening price, or the top bid and a step (step_bp of his value, at least min_step). */
    public static function next(int $opening, ?int $top, int $value): int
    {
        if ($top === null) {
            return $opening;
        }
        $c = config('game.auctions');

        return $top + max((int) $c['min_step'], intdiv($value * (int) $c['step_bp'], 10000));
    }

    public static function bid(int $clubId, int $playerId, int $amount, string $key): array
    {
        return DB::transaction(function () use ($clubId, $playerId, $amount, $key) {
            $club = DB::table('clubs')->where('id', $clubId)->first();
            if (DB::table('auction_bids')->where('idempotency_key', $key)->exists()) {
                return self::one((int) $club->league_id, $playerId, $clubId);
            }
            Market::assertOpen((int) $club->league_id);
            $l = DB::table('transfer_listings')->join('clubs', 'clubs.id', '=', 'transfer_listings.club_id')->where('transfer_listings.player_id', $playerId)
                ->where('clubs.league_id', $club->league_id)->whereNotNull('transfer_listings.auction_ends_at')
                ->select('transfer_listings.*', 'clubs.league_id')->first();
            abort_unless($l, 404, __('لا مزاد على هذا اللاعب.'));
            $now = GameClock::now();
            if (Carbon::parse($l->auction_ends_at, 'UTC')->lte($now)) {
                throw new HttpException(409, __('انتهى المزاد.'));
            }
            if ((int) $l->club_id === $clubId) {
                throw new HttpException(409, __('لا تزايد على لاعبك.'));
            }
            $top = self::top($playerId);
            if ($top && (int) $top->club_id === $clubId) {
                throw new HttpException(409, __('مزايدتك هي الأعلى الآن.'));
            }
            $value = (int) DB::table('players')->where('id', $playerId)->value('value');
            $least = self::next((int) $l->price, $top ? (int) $top->amount : null, $value);
            if ($amount < $least) {
                throw new HttpException(422, sprintf(__('أقل مزايدة الآن %s.'), number_format($least)));
            }
            // The coaches' fair price holds here too: at most human_trade_max_bp of his value.
            $cap = intdiv($value * (int) config('game.economy.human_trade_max_bp'), 10000);
            if ($amount > $cap) {
                throw new HttpException(422, sprintf(__('أعلى مزايدة على هذا اللاعب %s.'), number_format($cap)));
            }
            if ((int) $club->balance < $amount) {
                throw new HttpException(409, __('رصيد ناديك لا يكفي لهذه المزايدة.'));
            }
            DB::table('auction_bids')->insert(['player_id' => $playerId, 'club_id' => $clubId, 'amount' => $amount, 'idempotency_key' => $key, 'created_at' => $now]);
            // A bid in the last seconds moves the end, so the others can answer.
            $extend = (int) config('game.auctions.extend_seconds');
            if (Carbon::parse($l->auction_ends_at, 'UTC')->lt($now->copy()->addSeconds($extend))) {
                DB::table('transfer_listings')->where('player_id', $playerId)->update(['auction_ends_at' => $now->copy()->addSeconds($extend)]);
            }
            $name = self::playerName($playerId);
            if ($top) {
                $was = DB::table('clubs')->where('id', $top->club_id)->first();
                Inbox::send($was?->user_id, 'auction_outbid', ['player' => $name, 'price' => $amount], (int) $club->league_id, (int) $top->club_id);
            }

            return self::one((int) $club->league_id, $playerId, $clubId);
        });
    }

    /** Every minute: the auctions that ended become deals, the best payable bid first. Returns how many were sold. */
    public static function settle(): int
    {
        $n = 0;
        foreach (DB::table('transfer_listings')->whereNotNull('auction_ends_at')->where('auction_ends_at', '<=', GameClock::now())->get() as $l) {
            $n += self::close($l) ? 1 : 0;
        }

        return $n;
    }

    private static function close(object $l): bool
    {
        $playerId = (int) $l->player_id;
        $seller = DB::table('clubs')->where('id', $l->club_id)->first();
        $name = self::playerName($playerId);
        foreach (DB::table('auction_bids')->where('player_id', $playerId)->orderByDesc('amount')->orderBy('id')->get() as $b) {
            try {
                DB::transaction(function () use ($b, $l, $playerId) {
                    $offer = Transfers::offer((int) $b->club_id, (int) $l->club_id, (int) $b->amount, [$playerId], [], "auction:{$b->id}");
                    Transfers::accept($offer, (int) $l->club_id);
                });
            } catch (Throwable) {
                continue;
            }
            DB::table('auction_bids')->where('player_id', $playerId)->delete();
            $buyer = DB::table('clubs')->where('id', $b->club_id)->first();
            Inbox::send($buyer->user_id, 'auction_won', ['player' => $name, 'price' => (int) $b->amount], (int) $seller->league_id, (int) $buyer->id);
            Inbox::send($seller->user_id, 'auction_sold', ['player' => $name, 'price' => (int) $b->amount, 'to' => $buyer->name], (int) $seller->league_id, (int) $seller->id);

            return true;
        }
        // Nobody bid, or no bid could be paid: the player stays, his listing goes.
        DB::table('auction_bids')->where('player_id', $playerId)->delete();
        DB::table('transfer_listings')->where('player_id', $playerId)->delete();
        Inbox::send($seller->user_id, 'auction_sold', ['player' => $name, 'price' => 0], (int) $seller->league_id, (int) $seller->id);

        return false;
    }

    private static function top(int $playerId): ?object
    {
        return DB::table('auction_bids')->where('player_id', $playerId)->orderByDesc('amount')->orderBy('id')->first();
    }

    private static function one(int $leagueId, int $playerId, int $clubId): array
    {
        return collect(self::of($leagueId, $clubId))->firstWhere('player_id', $playerId) ?? [];
    }

    private static function playerName(int $playerId): string
    {
        return (string) DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.id', $playerId)->value('master_players.name');
    }
}
