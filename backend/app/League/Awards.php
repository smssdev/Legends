<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/**
 * [X61 E5] The season's awards so far, worked out from its finished matches (no table of their own): the best player
 * (the highest average rating with enough matches), the best young one (game.awards.young_age or under), the player
 * of the last round, the top scorer and assister, and the longest winning run. Ratings are the reports' own (300 to
 * 1000, shown as 3.0 to 10.0).
 */
class Awards
{
    public static function of(int $leagueId, int $seasonId): array
    {
        $cfg = config('game.awards');
        $matches = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
            ->where('fixtures.season_id', $seasonId)->where('fixtures.status', 'finished')->where('fixtures.is_bye', false)
            ->get(['matches.id', 'fixtures.round', 'fixtures.competition']);
        if ($matches->isEmpty()) {
            return ['matches' => 0, 'mvp' => null, 'young' => null, 'of_the_round' => null, 'scorer' => null, 'assister' => null, 'run' => null];
        }
        // One report per match holds both sides' ratings.
        $reports = DB::table('match_reports')->whereIn('match_id', $matches->pluck('id'))->orderBy('match_id')->get(['match_id', 'report'])->unique('match_id');
        $round = (int) $matches->where('competition', 'league')->max('round');
        $roundIds = $matches->where('competition', 'league')->where('round', $round)->pluck('id')->all();
        $per = [];
        $best = null;
        foreach ($reports as $r) {
            $ratings = json_decode($r->report, true)['ratings'] ?? [];
            foreach (['home', 'away'] as $side) {
                foreach ($ratings[$side] ?? [] as $p) {
                    $id = (int) $p['id'];
                    $per[$id] ??= ['sum' => 0, 'n' => 0, 'goals' => 0, 'assists' => 0];
                    $per[$id]['sum'] += (int) $p['rating'];
                    $per[$id]['n']++;
                    $per[$id]['goals'] += (int) ($p['goals'] ?? 0);
                    $per[$id]['assists'] += (int) ($p['assists'] ?? 0);
                    if (in_array((int) $r->match_id, $roundIds, true) && ($best === null || (int) $p['rating'] > $best[1])) {
                        $best = [$id, (int) $p['rating']];
                    }
                }
            }
        }
        $people = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->leftJoin('clubs', 'clubs.id', '=', 'players.club_id')
            ->whereIn('players.id', array_keys($per))->get(['players.id', 'master_players.name', 'master_players.age', 'master_players.position', 'clubs.id as club_id', 'clubs.name as club'])->keyBy('id');
        $card = function (int $id, array $extra = []) use ($people, $per) {
            $p = $people[$id] ?? null;

            return $p ? ['player' => ['id' => $id, 'name' => $p->name, 'age' => (int) $p->age, 'position' => $p->position],
                'club' => $p->club_id ? ['id' => (int) $p->club_id, 'name' => $p->club] : null,
                'matches' => $per[$id]['n'], 'average_x10' => intdiv($per[$id]['sum'], 10 * max(1, $per[$id]['n']))] + $extra : null;
        };
        // Enough matches to count: half the most anyone has played, and at least min_matches.
        $enough = max((int) $cfg['min_matches'], intdiv(max(array_column($per, 'n') ?: [0]), 2));
        $ranked = array_filter($per, fn ($s) => $s['n'] >= $enough);
        uksort($ranked, fn ($a, $b) => [intdiv($per[$b]['sum'], $per[$b]['n']), $per[$b]['n']] <=> [intdiv($per[$a]['sum'], $per[$a]['n']), $per[$a]['n']]);
        $young = array_filter(array_keys($ranked), fn ($id) => isset($people[$id]) && (int) $people[$id]->age <= (int) $cfg['young_age']);
        $top = fn (string $k) => ($ids = array_keys(array_filter($per, fn ($s) => $s[$k] > 0)))
            ? array_reduce($ids, fn ($c, $id) => $c === null || $per[$id][$k] > $per[$c][$k] ? $id : $c) : null;
        $scorer = $top('goals');
        $assister = $top('assists');
        $streaks = SeasonStats::of($leagueId, $seasonId, 1)['streaks'];
        $run = $streaks[0] ?? null;

        return [
            'matches' => $matches->count(),
            'mvp' => ($id = array_key_first($ranked)) !== null ? $card($id) : null,
            'young' => $young ? $card(reset($young)) : null,
            'of_the_round' => $best ? $card($best[0], ['round' => $round, 'rating_x10' => intdiv($best[1], 10)]) : null,
            'scorer' => $scorer !== null ? $card($scorer, ['goals' => $per[$scorer]['goals']]) : null,
            'assister' => $assister !== null ? $card($assister, ['assists' => $per[$assister]['assists']]) : null,
            'run' => $run && $run['best']['W'] > 0 ? ['club' => $run['club'], 'wins' => $run['best']['W']] : null,
        ];
    }
}
