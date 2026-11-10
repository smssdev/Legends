<?php

namespace App\Market;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 50 M19] Negotiating with a computer club over one of its players, instead of its fixed price (125%).
 * The club asks its price; the coach offers. An offer at its ask or more buys him at the ask (Market::buy at the agreed
 * price). Below it the club meets him halfway, never under its floor (game.negotiation.floor_bp of his value), for up
 * to game.negotiation.rounds rounds; then its last ask stands. An offer under insult_bp of the floor ends the talk for
 * the day. Everything is read from the stored talk, so the same offers always get the same answers.
 */
class BotNegotiation
{
    public static function floor(object $player): int
    {
        return intdiv((int) $player->value * (int) config('game.negotiation.floor_bp'), 10000);
    }

    /** The talk as the screen shows it. */
    public static function view(int $clubId, int $playerId): array
    {
        $p = self::player($clubId, $playerId);
        $t = self::talk($clubId, $p);

        return self::shape($t, $p);
    }

    public static function offer(int $clubId, int $playerId, int $amount, string $key): array
    {
        $p = self::player($clubId, $playerId);

        return DB::transaction(function () use ($clubId, $p, $amount, $key) {
            $t = self::talk($clubId, $p);
            if ($t->status === 'closed') {
                throw new HttpException(409, __('أنهى النادي التفاوض اليوم. عُد غداً.'));
            }
            if ($t->status === 'done') {
                throw new HttpException(409, __('اتفقتما من قبل.'));
            }
            $now = GameClock::now();
            $c = config('game.negotiation');
            if ($amount >= (int) $t->ask) {
                Market::buy($clubId, (int) $p->id, "deal:{$key}", false, (int) $t->ask);
                DB::table('bot_negotiations')->where('id', $t->id)->update(['status' => 'done', 'updated_at' => $now]);

                return self::shape(DB::table('bot_negotiations')->find($t->id), $p) + ['bought' => true];
            }
            $floor = self::floor($p);
            if ($amount * 10000 < $floor * (int) $c['insult_bp'] || (int) $t->round >= (int) $c['rounds']) {
                DB::table('bot_negotiations')->where('id', $t->id)->update(['status' => 'closed', 'updated_at' => $now]);

                return self::shape(DB::table('bot_negotiations')->find($t->id), $p) + ['bought' => false];
            }
            $ask = max($floor, intdiv((int) $t->ask + $amount, 2));
            DB::table('bot_negotiations')->where('id', $t->id)->update(['round' => (int) $t->round + 1, 'ask' => $ask, 'updated_at' => $now]);

            return self::shape(DB::table('bot_negotiations')->find($t->id), $p) + ['bought' => false];
        });
    }

    /** The open talk, or a new one at the club's price; a talk from another day starts again. */
    private static function talk(int $clubId, object $p): object
    {
        $now = GameClock::now();
        $t = DB::table('bot_negotiations')->where('club_id', $clubId)->where('player_id', $p->id)->first();
        if ($t && Carbon::parse($t->expires_at, 'UTC')->gt($now) && $t->status !== 'done') {
            return $t;
        }
        $row = ['round' => 0, 'ask' => (int) Market::price($p, $clubId), 'status' => 'open', 'expires_at' => $now->copy()->addDay(), 'updated_at' => $now];
        DB::table('bot_negotiations')->updateOrInsert(['club_id' => $clubId, 'player_id' => $p->id], $row + ['created_at' => $now]);

        return DB::table('bot_negotiations')->where('club_id', $clubId)->where('player_id', $p->id)->first();
    }

    private static function shape(object $t, object $p): array
    {
        return ['player_id' => (int) $p->id, 'price' => (int) Market::price($p, (int) $t->club_id), 'ask' => (int) $t->ask,
            'round' => (int) $t->round, 'rounds' => (int) config('game.negotiation.rounds'), 'status' => $t->status,
            'expires_at' => Carbon::parse($t->expires_at, 'UTC')->toIso8601ZuluString()];
    }

    /** A computer club's player in the coach's league, for sale. */
    private static function player(int $clubId, int $playerId): object
    {
        $league = (int) DB::table('clubs')->where('id', $clubId)->value('league_id');
        Market::assertOpen($league);
        $p = DB::table('players')->where('id', $playerId)->where('league_id', $league)->first();
        abort_unless($p && $p->club_id && DB::table('clubs')->where('id', $p->club_id)->whereNull('user_id')->exists(), 404, __('التفاوض مع أندية الحاسوب فقط.'));

        return $p;
    }
}
