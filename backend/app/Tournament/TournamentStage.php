<?php

namespace App\Tournament;

use App\League\Standings;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 27] The end of the groups: each group's table decides who goes on, and the first knockout ties are filled
 * from it ("A1" is group A's winner). Once: a tie already filled is left as it is.
 */
class TournamentStage
{
    /** The groups' tables: [group => rows in order]. */
    public static function tables(int $seasonId, int $leagueId): array
    {
        $groups = DB::table('clubs')->where('league_id', $leagueId)->whereNotNull('group_no')->get(['id', 'group_no'])
            ->groupBy('group_no')->sortKeys();
        $tables = [];
        foreach ($groups as $g => $clubs) {
            $tables[(int) $g] = Standings::table($seasonId, $clubs->pluck('id')->map(fn ($id) => (int) $id)->all());
        }

        return $tables;
    }

    public static function groupsDone(int $seasonId): void
    {
        $leagueId = (int) DB::table('seasons')->where('id', $seasonId)->value('league_id');
        $tables = self::tables($seasonId, $leagueId);
        $now = GameClock::now();
        foreach (DB::table('cup_ties')->where('season_id', $seasonId)->where(fn ($q) => $q->whereNotNull('home_from')->orWhereNotNull('away_from'))->get() as $tie) {
            $sides = [];
            foreach (['home', 'away'] as $side) {
                $from = $tie->{$side.'_from'};
                if ($from && $tie->{$side.'_id'} === null) {
                    $club = $tables[ord($from[0]) - 64][(int) substr($from, 1) - 1]['id'] ?? null;
                    if ($club) {
                        $sides[$side.'_id'] = $club;
                    }
                }
            }
            if ($sides) {
                DB::table('cup_ties')->where('id', $tie->id)->update($sides + ['updated_at' => $now]);
                DB::table('fixtures')->where('id', $tie->fixture_id)->update($sides + ['updated_at' => $now]);
            }
        }
        // Each coach hears whether his team goes on.
        $through = DB::table('cup_ties')->where('season_id', $seasonId)->get(['home_id', 'away_id'])->flatMap(fn ($t) => [$t->home_id, $t->away_id])->filter()->flip();
        $name = DB::table('leagues')->where('id', $leagueId)->value('name');
        foreach (DB::table('clubs')->where('league_id', $leagueId)->whereNotNull('user_id')->get() as $club) {
            Inbox::send($club->user_id, 'tournament_groups', ['tournament' => $name, 'through' => isset($through[$club->id]), 'league_id' => $leagueId], $leagueId, $club->id);
        }
    }
}
