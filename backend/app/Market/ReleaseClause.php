<?php

namespace App\Market;

use App\Messages\Inbox;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 50 M19] The release clause: any coach's player can be taken at once, without his coach's answer, by paying
 * the clause: game.economy.release_clause_bp of his value (never above the coaches' highest fair price). It is a deal
 * like any other between coaches (Transfers::offer, then accept for the seller), so every limit holds: the fair
 * price, the pair cap, the squads' sizes, a sheet locked for a match, and the buyer's money.
 */
class ReleaseClause
{
    public static function of(object $player): int
    {
        $c = config('game.economy');

        return intdiv((int) $player->value * min((int) $c['release_clause_bp'], (int) $c['human_trade_max_bp']), 10000);
    }

    /** What taking this player costs this club, and whether it may: [clause, can, why]. */
    public static function quote(int $clubId, int $playerId): array
    {
        [$p, $seller] = self::target($clubId, $playerId);
        $clause = self::of($p);
        $balance = (int) DB::table('clubs')->where('id', $clubId)->value('balance');

        return ['player_id' => $playerId, 'clause' => $clause, 'club' => ['id' => (int) $seller->id, 'name' => $seller->name],
            'can' => $balance >= $clause, 'why' => $balance >= $clause ? null : __('رصيد ناديك لا يكفي للشرط الجزائي.')];
    }

    public static function pay(int $clubId, int $playerId, string $key): array
    {
        [$p, $seller] = self::target($clubId, $playerId);
        $clause = self::of($p);
        DB::transaction(function () use ($clubId, $seller, $playerId, $clause, $key) {
            $offer = Transfers::offer($clubId, (int) $seller->id, $clause, [$playerId], [], "clause:{$key}");
            if (DB::table('transfer_offers')->where('id', $offer)->value('status') === 'pending') {
                Transfers::accept($offer, (int) $seller->id);
            }
        });
        $buyer = DB::table('clubs')->where('id', $clubId)->first();
        $name = (string) DB::table('master_players')->where('id', $p->master_player_id)->value('name');
        Inbox::send($seller->user_id, 'release_clause', ['player' => $name, 'price' => $clause, 'to' => $buyer->name], (int) $seller->league_id, (int) $seller->id);

        return ['player_id' => $playerId, 'price' => $clause];
    }

    /** The player and his coach's club: in this league, another coach's. */
    private static function target(int $clubId, int $playerId): array
    {
        $league = (int) DB::table('clubs')->where('id', $clubId)->value('league_id');
        $p = DB::table('players')->where('id', $playerId)->where('league_id', $league)->first();
        abort_unless($p && $p->club_id, 404, __('اللاعب غير موجود في هذا الدوري.'));
        if ((int) $p->club_id === $clubId) {
            throw new HttpException(409, __('اللاعب في فريقك بالفعل.'));
        }
        $seller = DB::table('clubs')->where('id', $p->club_id)->first();
        if ($seller->user_id === null) {
            throw new HttpException(409, __('هذا نادي حاسوب: اشترِ منه من السوق أو فاوضه.'));
        }

        return [$p, $seller];
    }
}
