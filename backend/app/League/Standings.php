<?php

namespace App\League;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/** The league's final order [PLAN 2.5]: points, goal difference, goals scored, then strength (as the table shows). */
class Standings
{
    /**
     * @return list<int> club ids, first place first
     *
     * [X45] Kept in the server's own cache: it changes only when a league match is finished or the FA takes points,
     * and both clear it (forget()); the home screen and the league's pages ask for it many times a minute.
     */
    public static function order(int $seasonId): array
    {
        return Cache::remember("standings:{$seasonId}", 120, fn () => self::compute($seasonId));
    }

    /** After the change commits, so no reader caches the table as it was before it. */
    public static function forget(int $seasonId): void
    {
        DB::afterCommit(fn () => Cache::forget("standings:{$seasonId}"));
    }

    private static function compute(int $seasonId): array
    {
        return array_column(self::table($seasonId), 'id');
    }

    /**
     * The table's rows in order: points, goal difference, goals scored, strength; of every club, or of one group's
     * clubs in a tournament [Sprint 29].
     *
     * @param  list<int>|null  $clubIds
     * @param  list<int>  $except  fixtures left out (the table as it was before them, Sprint 64 W3)
     * @return list<array{id: int, pts: int, gd: int, gf: int, st: int, p: int, w: int, d: int, l: int, ga: int}>
     */
    public static function table(int $seasonId, ?array $clubIds = null, array $except = []): array
    {
        $leagueId = (int) DB::table('seasons')->where('id', $seasonId)->value('league_id');
        $rows = DB::table('clubs')->where('league_id', $leagueId)->when($clubIds !== null, fn ($q) => $q->whereIn('id', $clubIds))->get(['id', 'strength_snapshot'])
            ->mapWithKeys(fn ($c) => [$c->id => ['id' => (int) $c->id, 'pts' => 0, 'gd' => 0, 'gf' => 0, 'st' => (int) $c->strength_snapshot, 'p' => 0, 'w' => 0, 'd' => 0, 'l' => 0, 'ga' => 0]])->all();
        $done = DB::table('fixtures')->where('season_id', $seasonId)->where('competition', 'league')->where('is_bye', false)->where('status', 'finished')
            ->when($except, fn ($q) => $q->whereNotIn('id', $except))->get();
        foreach ($done as $f) {
            foreach ([[$f->home_id, $f->home_goals, $f->away_goals], [$f->away_id, $f->away_goals, $f->home_goals]] as [$id, $for, $against]) {
                if (! isset($rows[$id])) {
                    continue;
                }
                $rows[$id]['p']++;
                $rows[$id][$for > $against ? 'w' : ($for === $against ? 'd' : 'l')]++;
                $rows[$id]['ga'] += $against;
                $rows[$id]['pts'] += $for > $against ? 3 : ($for === $against ? 1 : 0);
                $rows[$id]['gd'] += $for - $against;
                $rows[$id]['gf'] += $for;
            }
        }
        // Points the FA took off [X28].
        foreach (Integrity::deductions($seasonId) as $id => $points) {
            if (isset($rows[$id])) {
                $rows[$id]['pts'] -= $points;
            }
        }
        usort($rows, fn ($a, $b) => [$b['pts'], $b['gd'], $b['gf'], $b['st']] <=> [$a['pts'], $a['gd'], $a['gf'], $a['st']]);

        return $rows;
    }
}
