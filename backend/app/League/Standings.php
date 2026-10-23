<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/** The league's final order [PLAN 2.5]: points, goal difference, goals scored, then strength (as the table shows). */
class Standings
{
    /** @return list<int> club ids, first place first */
    public static function order(int $seasonId): array
    {
        $leagueId = (int) DB::table('seasons')->where('id', $seasonId)->value('league_id');
        $rows = DB::table('clubs')->where('league_id', $leagueId)->get(['id', 'strength_snapshot'])
            ->mapWithKeys(fn ($c) => [$c->id => ['id' => $c->id, 'pts' => 0, 'gd' => 0, 'gf' => 0, 'st' => (int) $c->strength_snapshot]])->all();
        $done = DB::table('fixtures')->where('season_id', $seasonId)->where('competition', 'league')->where('is_bye', false)->where('status', 'finished')->get();
        foreach ($done as $f) {
            foreach ([[$f->home_id, $f->home_goals, $f->away_goals], [$f->away_id, $f->away_goals, $f->home_goals]] as [$id, $for, $against]) {
                $rows[$id]['pts'] += $for > $against ? 3 : ($for === $against ? 1 : 0);
                $rows[$id]['gd'] += $for - $against;
                $rows[$id]['gf'] += $for;
            }
        }
        usort($rows, fn ($a, $b) => [$b['pts'], $b['gd'], $b['gf'], $b['st']] <=> [$a['pts'], $a['gd'], $a['gf'], $a['st']]);

        return array_column($rows, 'id');
    }
}
