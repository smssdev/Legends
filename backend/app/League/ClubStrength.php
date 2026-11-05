<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/**
 * [X98] A club's strength (clubs.strength_snapshot, in hundredths): the average rating of its best SQUAD players as
 * they are now, with their training. The same rule the data import gives a club at the start (DataImport: the best 18
 * of its squad), so a new league's clubs keep their number; then buying, selling, loans, the academy and training move
 * it. Called after every change to a squad, inside the change's own transaction. A club with no players keeps its last.
 */
final class ClubStrength
{
    public const SQUAD = 18;

    /** The strength of a squad from its ratings (overall + training), in hundredths; null for an empty squad. */
    public static function of(array $ratings): ?int
    {
        rsort($ratings);
        $best = array_slice($ratings, 0, self::SQUAD);

        return $best ? intdiv(array_sum($best) * 100, count($best)) : null;
    }

    /** Recompute these clubs' strength from their squads now. */
    public static function refresh(int ...$clubIds): void
    {
        $clubIds = array_values(array_unique(array_filter($clubIds)));
        if (! $clubIds) {
            return;
        }
        $ratings = [];
        foreach (DB::table('players')->whereIn('club_id', $clubIds)->get(['club_id', 'overall', 'training_bonus']) as $p) {
            $ratings[(int) $p->club_id][] = (int) $p->overall + (int) $p->training_bonus;
        }
        foreach ($clubIds as $id) {
            $strength = self::of($ratings[$id] ?? []);
            if ($strength !== null) {
                DB::table('clubs')->where('id', $id)->where('strength_snapshot', '!=', $strength)->update(['strength_snapshot' => $strength]);
            }
        }
    }

    /** Every club of a league (a new season, when the players go home). */
    public static function refreshLeague(int $leagueId): void
    {
        self::refresh(...DB::table('clubs')->where('league_id', $leagueId)->pluck('id')->map(fn ($id) => (int) $id)->all());
    }
}
