<?php

namespace App\Market;

use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * The market pool [PLAN 2.7, Sprint 24]: about 300 players from outside the league's clubs, renewed when each window
 * opens (the first one when the league is made) and every game.economy.pool_hours [X6, 2026-10-24]. They come from
 * every league in the data, whatever the league's own template, in every line (pool_lines), and as strong as this
 * league: from its pool_level_from_pct percentile to its best player. The players of the old pool leave it; the ones
 * a coach sold to it stay until the next renewal like the rest.
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
            // The scouts' finds nobody bought go with it.
            DB::table('players')->where('league_id', $leagueId)->whereNull('club_id')->whereNotNull('scouted_by')->update(['scouted_by' => null]);
            DB::table('leagues')->where('id', $leagueId)->update(['pool_renewed_at' => GameClock::now()]);
            // The league's level, with its training: from the given percentile to its best.
            $levels = DB::table('players')->where('league_id', $leagueId)->whereNotNull('club_id')
                ->selectRaw('overall + training_bonus as level')->orderBy('level')->pluck('level');
            if ($levels->isEmpty()) {
                return 0;
            }
            $low = (int) $levels[intdiv($levels->count() * (int) config('game.economy.pool_level_from_pct'), 100)];
            $high = (int) $levels->last();
            $version = DB::table('master_players')->max('data_version');
            $taken = DB::table('players')->where('league_id', $leagueId)->select('master_player_id');
            $size = (int) config('game.economy.pool_size');
            $ids = collect();
            foreach (config('game.economy.pool_lines') as $line => $pct) {
                $ids = $ids->merge(DB::table('master_players')->where('data_version', $version)->where('line', $line)->whereBetween('overall', [$low, $high])
                    ->whereNotIn('id', $taken)->inRandomOrder()->limit(intdiv($size * $pct, 100))->pluck('id'));
            }
            $now = GameClock::now();
            foreach ($ids->chunk(200) as $chunk) {
                DB::table('players')->insertUsing(['league_id', 'club_id', 'master_player_id', 'overall', 'base_value', 'value', 'in_pool', 'created_at', 'updated_at'],
                    DB::table('master_players')->whereIn('id', $chunk->all())
                        ->selectRaw('?, null, id, overall, value, value, true, ?, ?', [$leagueId, $now, $now]));
            }

            return $ids->count();
        });
    }

    /** Every minute: a window that has opened renews its league's pool, once; and so does pool_hours since the last. */
    public static function due(): int
    {
        $renewed = 0;
        $windows = DB::table('transfer_windows')->join('seasons', 'seasons.id', '=', 'transfer_windows.season_id')
            ->whereNull('transfer_windows.pool_at')->where('transfer_windows.opens_at', '<=', GameClock::now())
            ->select('transfer_windows.id', 'seasons.league_id')->get();
        foreach ($windows as $w) {
            $renewed += self::renew((int) $w->league_id, (int) $w->id) === null ? 0 : 1;
        }
        // Then every league whose pool is pool_hours old (the window just renewed is not).
        $stale = DB::table('leagues')->where('status', '!=', 'finished')
            ->where(fn ($q) => $q->whereNull('pool_renewed_at')->orWhere('pool_renewed_at', '<=', GameClock::now()->copy()->subHours((int) config('game.economy.pool_hours'))))
            ->pluck('id');
        foreach ($stale as $leagueId) {
            if (! Market::closed((int) $leagueId)) {
                $renewed += self::renew((int) $leagueId) === null ? 0 : 1;
            }
        }

        return $renewed;
    }
}
