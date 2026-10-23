<?php

namespace App\Market;

use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * The market pool [PLAN 2.7, Sprint 24]: about 300 players from outside the league's clubs, near the league's
 * level, renewed when each window opens (the first one when the league is made). The players of the old pool
 * leave it; the ones a coach sold to it stay until the next renewal like the rest.
 */
class Pool
{
    /** The players added, or null when this window was renewed already. */
    public static function renew(int $leagueId, ?int $windowId = null): ?int
    {
        return DB::transaction(function () use ($leagueId, $windowId) {
            if ($windowId && DB::table('transfer_windows')->where('id', $windowId)->whereNull('pool_at')->update(['pool_at' => GameClock::now()]) !== 1) {
                return null;
            }
            DB::table('players')->where('league_id', $leagueId)->whereNull('club_id')->where('in_pool', true)->update(['in_pool' => false]);
            // The league's level: from its weaker players to its best.
            $levels = DB::table('players')->where('league_id', $leagueId)->whereNotNull('club_id')->orderBy('overall')->pluck('overall');
            if ($levels->isEmpty()) {
                return 0;
            }
            $low = (int) $levels[intdiv($levels->count(), 10)];
            $high = (int) $levels->last();
            $version = DB::table('master_players')->max('data_version');
            $taken = DB::table('players')->where('league_id', $leagueId)->select('master_player_id');
            $ids = DB::table('master_players')->where('data_version', $version)->whereBetween('overall', [$low, $high])
                ->whereNotIn('id', $taken)->inRandomOrder()->limit((int) config('game.economy.pool_size'))->pluck('id');
            $now = GameClock::now();
            foreach ($ids->chunk(200) as $chunk) {
                DB::table('players')->insertUsing(['league_id', 'club_id', 'master_player_id', 'overall', 'base_value', 'value', 'in_pool', 'created_at', 'updated_at'],
                    DB::table('master_players')->whereIn('id', $chunk->all())
                        ->selectRaw('?, null, id, overall, value, value, 1, ?, ?', [$leagueId, $now, $now]));
            }

            return $ids->count();
        });
    }

    /** Every minute: a window that has opened renews its league's pool, once. */
    public static function due(): int
    {
        $renewed = 0;
        $windows = DB::table('transfer_windows')->join('seasons', 'seasons.id', '=', 'transfer_windows.season_id')
            ->whereNull('transfer_windows.pool_at')->where('transfer_windows.opens_at', '<=', GameClock::now())
            ->select('transfer_windows.id', 'seasons.league_id')->get();
        foreach ($windows as $w) {
            $renewed += self::renew((int) $w->league_id, (int) $w->id) === null ? 0 : 1;
        }

        return $renewed;
    }
}
