<?php

namespace App\Market;

use App\Data\PlayerValuation;
use App\Support\GameClock;
use App\TimedEvents\TimedEvents;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The market pool [PLAN 2.7, Sprint 24]: about 300 players from outside the league's clubs, renewed when each window
 * opens (the first one when the league is made) and every game.economy.pool_hours [X6, 2026-10-24]. They come from
 * every league in the data, whatever the league's own template, in every line (pool_lines), and as strong as this
 * league: from its pool_level_from_pct percentile to its best player. The players of the old pool leave it; the ones
 * a coach sold to it stay until the next renewal like the rest. From mid-season a few stars come too (stars()).
 * [Sprint 23] The admin's timed events: a transfer madness renews it faster, and while special offers, players of
 * the week or legends run, each renewal brings them (specials()), and their start renews it at once.
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
            DB::table('players')->where('league_id', $leagueId)->whereNull('club_id')->where('in_pool', true)
                ->update(['in_pool' => false, 'pool_star' => false, 'pool_kind' => null, 'pool_price_bp' => null]);
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

            return $ids->count() + self::stars($leagueId, $high, $version, $now) + self::specials($leagueId, $ids->all(), $high, $version, $now);
        });
    }

    /**
     * [Sprint 23] The special players of the running events: offers (some of the new players at a discount),
     * players of the week (some in form, a few points above their rating, which stays with them) and legends (from
     * the league's best up to power points over it, at the legends' price). Marked for the market to show them.
     */
    private static function specials(int $leagueId, array $newIds, int $high, int $version, $now): int
    {
        $kinds = config('game.timed_events.kinds');
        $fresh = fn (int $n, ?array $except = null) => DB::table('players')->where('league_id', $leagueId)->whereNull('club_id')->where('in_pool', true)
            ->whereIn('master_player_id', $newIds)->whereNull('pool_kind')->where('pool_star', false)
            ->inRandomOrder()->limit($n)->pluck('id');
        $added = 0;
        if ($e = TimedEvents::running('offers', $leagueId)) {
            $bp = intdiv((int) config('game.economy.buy_from_pool_bp') * (10000 - min(9000, (int) $e->power)), 10000);
            DB::table('players')->whereIn('id', $fresh((int) ($e->count ?: $kinds['offers']['count']))->all())->update(['pool_kind' => 'offer', 'pool_price_bp' => $bp]);
        }
        if ($e = TimedEvents::running('in_form', $leagueId)) {
            $valuation = PlayerValuation::fromConfig();
            $ceiling = (int) config('game.training.ceiling', 99);
            $rows = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->whereIn('players.id', $fresh((int) ($e->count ?: $kinds['in_form']['count']))->all())
                ->get(['players.id', 'players.overall', 'master_players.age', 'master_players.line', 'master_players.potential']);
            foreach ($rows as $p) {
                $bonus = max(0, min((int) $e->power, $ceiling - (int) $p->overall));
                DB::table('players')->where('id', $p->id)->update(['pool_kind' => 'in_form', 'training_bonus' => $bonus,
                    'value' => $valuation->value((int) $p->overall + $bonus, (int) $p->age, $p->line, (int) $p->potential)]);
            }
        }
        if ($e = TimedEvents::running('legends', $leagueId)) {
            $ids = DB::table('master_players')->where('data_version', $version)
                ->whereBetween('overall', [$high + 1, $high + (int) $e->power])
                ->whereNotIn('id', DB::table('players')->where('league_id', $leagueId)->select('master_player_id'))
                ->inRandomOrder()->limit((int) ($e->count ?: $kinds['legends']['count']))->pluck('id');
            if ($ids->isNotEmpty()) {
                DB::table('players')->insertUsing(['league_id', 'club_id', 'master_player_id', 'overall', 'base_value', 'value', 'in_pool', 'pool_kind', 'pool_price_bp', 'created_at', 'updated_at'],
                    DB::table('master_players')->whereIn('id', $ids->all())->selectRaw("?, null, id, overall, value, value, true, 'legend', ?, ?, ?",
                        [$leagueId, (int) $kinds['legends']['price_bp'], $now, $now]));
            }
            $added += $ids->count();
        }

        return $added;
    }

    /** When the league's pool renews next: pool_hours after the last, shorter in a transfer madness [Sprint 23]. */
    public static function renewsAt(object $league): ?Carbon
    {
        if (! $league->pool_renewed_at) {
            return null;
        }
        $seconds = intdiv((int) config('game.economy.pool_hours') * 3600 * 10000, TimedEvents::times('madness', (int) $league->id));

        return Carbon::parse($league->pool_renewed_at, 'UTC')->addSeconds($seconds);
    }

    /**
     * [UP11] From mid-season, a few stars from the parallel leagues: from the league's best to pool_stars_above over
     * it, any line, marked so the market shows them. Bought like any player of the pool.
     */
    private static function stars(int $leagueId, int $high, int $version, $now): int
    {
        $season = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->first();
        if (! $season || $season->rounds < 1 || $season->rounds_played * 10000 < $season->rounds * (int) config('game.economy.pool_stars_from_bp')) {
            return 0;
        }
        $ids = DB::table('master_players')->where('data_version', $version)
            ->whereBetween('overall', [$high, $high + (int) config('game.economy.pool_stars_above')])
            ->whereNotIn('id', DB::table('players')->where('league_id', $leagueId)->select('master_player_id'))
            ->inRandomOrder()->limit((int) config('game.economy.pool_stars'))->pluck('id');
        if ($ids->isNotEmpty()) {
            DB::table('players')->insertUsing(['league_id', 'club_id', 'master_player_id', 'overall', 'base_value', 'value', 'in_pool', 'pool_star', 'created_at', 'updated_at'],
                DB::table('master_players')->whereIn('id', $ids->all())->selectRaw('?, null, id, overall, value, value, true, true, ?, ?', [$leagueId, $now, $now]));
        }

        return $ids->count();
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
        // Then every league whose pool is pool_hours old (the window just renewed is not), sooner in a transfer
        // madness, and every league where an event that brings players started since its last renewal [Sprint 23].
        $started = collect(TimedEvents::runningOf(TimedEvents::PLAYERS));
        $stale = DB::table('leagues')->where('status', '!=', 'finished')->get(['id', 'pool_renewed_at'])
            ->filter(fn ($l) => ! $l->pool_renewed_at || Pool::renewsAt($l)->lte(GameClock::now())
                || $started->contains(fn ($e) => ($e->league_id === null || (int) $e->league_id === (int) $l->id)
                    && Carbon::parse($e->starts_at, 'UTC')->gt(Carbon::parse($l->pool_renewed_at, 'UTC'))))
            ->pluck('id');
        foreach ($stale as $leagueId) {
            if (! Market::closed((int) $leagueId)) {
                $renewed += self::renew((int) $leagueId) === null ? 0 : 1;
            }
        }

        return $renewed;
    }
}
