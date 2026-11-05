<?php

namespace App\Tournament;

use App\League\Standings;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 29] The end of the groups: each group's table decides who goes on, and the first knockout ties are filled
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
        $thirds = self::thirds($tables, (int) DB::table('leagues')->where('id', $leagueId)->value('best_thirds'));
        $now = GameClock::now();
        foreach (DB::table('cup_ties')->where('season_id', $seasonId)->where(fn ($q) => $q->whereNotNull('home_from')->orWhereNotNull('away_from'))->get() as $tie) {
            $sides = [];
            foreach (['home', 'away'] as $side) {
                $from = $tie->{$side.'_from'};
                if ($from && $tie->{$side.'_id'} === null) {
                    $club = str_starts_with($from, TournamentPlan::THIRD)
                        ? ($thirds[(int) substr($from, strlen(TournamentPlan::THIRD))] ?? null)
                        : ($tables[ord($from[0]) - 64][(int) substr($from, 1) - 1]['id'] ?? null);
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

    /**
     * [Sprint 43 A3] The best third-placed teams, by points, goal difference, goals and strength as a group's table,
     * each given a place "3:k" whose opponent (the winner of group k) is never its own group's. Pure: [k => club id].
     */
    public static function thirds(array $tables, int $count): array
    {
        if ($count <= 0) {
            return [];
        }
        $rows = [];
        foreach ($tables as $g => $table) {
            if (isset($table[2])) {
                $rows[] = $table[2] + ['group' => (int) $g];
            }
        }
        usort($rows, fn ($a, $b) => [$b['pts'], $b['gd'], $b['gf'], $b['st'], $a['group']] <=> [$a['pts'], $a['gd'], $a['gf'], $a['st'], $b['group']]);
        $best = array_slice($rows, 0, $count);
        // In order of rank, each into the first place left whose winner is of another group; a swap when one is stuck.
        $slots = array_fill(1, $count, null);
        foreach ($best as $row) {
            $free = array_keys(array_filter($slots, fn ($v) => $v === null));
            $fit = array_values(array_filter($free, fn ($k) => $k !== $row['group']));
            if ($fit) {
                $slots[$fit[0]] = $row;

                continue;
            }
            // Only its own group's place is left: swap with a placed one that may take it.
            $k = $free[0];
            foreach ($slots as $j => $other) {
                if ($other !== null && $other['group'] !== $k && $row['group'] !== $j) {
                    $slots[$k] = $other;
                    $slots[$j] = $row;

                    continue 2;
                }
            }
            $slots[$k] = $row;
        }

        return array_map(fn ($r) => $r === null ? null : $r['id'], $slots);
    }
}
