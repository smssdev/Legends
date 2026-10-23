<?php

namespace App\Season;

use App\League\CupBracket;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * Club objectives [PLAN 2.20, Sprint 33]: a place in the league and a stage in the cup, from the club's rank by
 * strength in its league. Set when the season is made (so a coach sees it when he picks a team), judged at its end.
 */
class Objectives
{
    /**
     * The league objective for the club ranked $rank (1 = strongest) of $teams. Pure.
     *
     * @return array{target: int, kind: string}
     */
    public static function league(int $rank, int $teams): array
    {
        $cfg = config('game.objectives');
        if ($rank === 1) {
            return ['target' => 1, 'kind' => 'title'];
        }
        $floor = $teams - intdiv($teams * (int) $cfg['bottom_bp'] + 9999, 10000);   // out of the bottom fifth
        $topQuarter = $rank * 4 <= $teams;
        $target = $rank + ($topQuarter ? (int) $cfg['top_quarter_slack'] : (int) $cfg['rest_slack']);
        if ($target >= $floor) {
            return ['target' => max(1, $floor), 'kind' => 'survive'];
        }

        return ['target' => $target, 'kind' => $topQuarter ? 'top' : 'mid'];
    }

    /** The cup stage the club ranked $rank of $teams must reach (one the bracket has). Pure. */
    public static function cup(int $rank, int $teams): string
    {
        $stages = array_values(array_diff(CupBracket::stages($teams), ['preliminary']));
        $wanted = config('game.objectives.cup_by_quarter')[min(3, intdiv(($rank - 1) * 4, $teams))];
        while (! in_array($wanted, $stages, true)) {
            $wanted = ['qf' => 'sf', 'sf' => 'final', 'r16' => 'qf'][$wanted] ?? 'final';
        }

        return $wanted;
    }

    /** Set every club's objectives for a season (once). */
    public static function set(int $seasonId): void
    {
        $leagueId = (int) DB::table('seasons')->where('id', $seasonId)->value('league_id');
        $clubs = DB::table('clubs')->where('league_id', $leagueId)->orderByDesc('strength_snapshot')->orderBy('id')->pluck('id')->values();
        $now = GameClock::now();
        $rows = [];
        foreach ($clubs as $i => $id) {
            $l = self::league($i + 1, $clubs->count());
            $rows[] = ['club_id' => $id, 'season_id' => $seasonId, 'competition' => 'league', 'target' => (string) $l['target'], 'kind' => $l['kind'], 'created_at' => $now, 'updated_at' => $now];
            $stage = self::cup($i + 1, $clubs->count());
            $rows[] = ['club_id' => $id, 'season_id' => $seasonId, 'competition' => 'cup', 'target' => $stage, 'kind' => $stage, 'created_at' => $now, 'updated_at' => $now];
        }
        DB::table('club_objectives')->insertOrIgnore($rows);
    }

    /** Judge every objective of a finished season: the place and the last stage reached, and the coach then. */
    public static function judge(int $seasonId, array $order): void
    {
        $now = GameClock::now();
        $places = array_flip($order);
        $stages = CupBracket::stages(count($order));
        foreach (DB::table('club_objectives')->where('season_id', $seasonId)->whereNull('achieved')->get() as $o) {
            $coach = DB::table('clubs')->where('id', $o->club_id)->value('user_id');
            if ($o->competition === 'league') {
                $place = ($places[$o->club_id] ?? count($order)) + 1;
                $update = ['result' => (string) $place, 'achieved' => $place <= (int) $o->target];
            } else {
                $reached = DB::table('cup_ties')->where('season_id', $seasonId)->where(fn ($q) => $q->where('home_id', $o->club_id)->orWhere('away_id', $o->club_id))->pluck('stage')->all();
                $won = DB::table('cup_ties')->where('season_id', $seasonId)->where('stage', 'final')->value('winner_id') === $o->club_id;
                $last = $won ? 'winner' : (collect($stages)->filter(fn ($s) => in_array($s, $reached, true))->last() ?? 'out');
                $index = fn ($s) => $s === 'winner' ? count($stages) : (int) array_search($s, $stages, true);
                $update = ['result' => $last, 'achieved' => $last !== 'out' && $index($last) >= $index($o->target)];
            }
            DB::table('club_objectives')->where('id', $o->id)->update($update + ['user_id' => $coach, 'updated_at' => $now]);
        }
    }
}
