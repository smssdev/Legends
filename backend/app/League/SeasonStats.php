<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/**
 * The league's statistics centre [X17]: everything anyone in the league may see of the season, from the
 * finished matches and the moves. The table in detail (with goals per match), the scorers and the assists,
 * the cards of players and clubs, each club's buying and selling, the squads' market value, and the runs of
 * results. Nothing hidden: no tactic, no reading, only what a spectator would count.
 */
class SeasonStats
{
    public static function of(int $leagueId, int $seasonId, int $top = 10): array
    {
        $clubs = DB::table('clubs')->where('league_id', $leagueId)->get(['id', 'name', 'code', 'master_club_id', 'user_id'])->keyBy('id');
        $card = fn (int $id) => ['id' => $id, 'name' => $clubs[$id]->name ?? '', 'code' => $clubs[$id]->code ?? '',
            'crest_url' => url('/api/v1/data/clubs/'.($clubs[$id]->master_club_id ?? 0).'/crest.svg')];

        $matches = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
            ->where('fixtures.season_id', $seasonId)->where('fixtures.status', 'finished')->where('fixtures.is_bye', false)
            ->orderBy('fixtures.scheduled_at')->orderBy('fixtures.id')
            ->get(['matches.id', 'fixtures.home_id', 'fixtures.away_id', 'fixtures.home_goals', 'fixtures.away_goals', 'fixtures.competition']);

        return [
            'matches' => $matches->count(),
            'table' => self::table($matches->where('competition', 'league'), $clubs->keys()->all(), $card, Integrity::deductions($seasonId)),
            ...self::people($matches->pluck('id')->all(), $card, $top),
            'finance' => self::finance($seasonId, $clubs->keys()->all(), $card),
            'value' => self::value($leagueId, $card),
            'streaks' => self::streaks($matches, $clubs->keys()->all(), $card),
        ];
    }

    /** The table with the goals per match (in hundredths, integers only). */
    private static function table($league, array $ids, \Closure $card, array $deducted = []): array
    {
        $rows = [];
        foreach ($ids as $id) {
            $rows[$id] = ['club' => $card($id), 'played' => 0, 'won' => 0, 'drawn' => 0, 'lost' => 0, 'goals_for' => 0, 'goals_against' => 0];
        }
        foreach ($league as $m) {
            foreach ([[$m->home_id, $m->home_goals, $m->away_goals], [$m->away_id, $m->away_goals, $m->home_goals]] as [$id, $for, $against]) {
                if (! isset($rows[$id])) {
                    continue;
                }
                $rows[$id]['played']++;
                $rows[$id]['goals_for'] += $for;
                $rows[$id]['goals_against'] += $against;
                $rows[$id][$for > $against ? 'won' : ($for === $against ? 'drawn' : 'lost')]++;
            }
        }
        $out = array_map(fn ($r) => $r + [
            'goal_difference' => $r['goals_for'] - $r['goals_against'],
            'points' => 3 * $r['won'] + $r['drawn'] - ($deducted[$r['club']['id']] ?? 0),
            'goals_per_match_x100' => $r['played'] ? intdiv(100 * $r['goals_for'], $r['played']) : 0,
            'conceded_per_match_x100' => $r['played'] ? intdiv(100 * $r['goals_against'], $r['played']) : 0,
        ], array_values($rows));
        usort($out, fn ($a, $b) => [$b['points'], $b['goal_difference'], $b['goals_for']] <=> [$a['points'], $a['goal_difference'], $a['goals_for']]);

        return array_map(fn ($r, $i) => ['position' => $i + 1] + $r, $out, array_keys($out));
    }

    /** The scorers, the assists and the cards, from each match's sheet (match_stats). */
    private static function people(array $matchIds, \Closure $card, int $top): array
    {
        $players = [];
        $clubCards = [];
        foreach (DB::table('match_stats')->whereIn('match_id', $matchIds)->get(['club_id', 'players']) as $sheet) {
            $clubCards[$sheet->club_id] ??= ['yellow' => 0, 'red' => 0];
            foreach (json_decode($sheet->players, true) ?? [] as $p) {
                $id = (int) $p['id'];
                $players[$id] ??= ['goals' => 0, 'assists' => 0, 'yellow' => 0, 'red' => 0, 'club_id' => (int) $sheet->club_id];
                $red = ($p['out'] ?? '') === 'red';
                $players[$id]['goals'] += (int) ($p['goals'] ?? 0);
                $players[$id]['assists'] += (int) ($p['assists'] ?? 0);
                // A second yellow is a red: the yellow card shown before it still counts.
                $players[$id]['yellow'] += min(1, (int) ($p['yc'] ?? 0));
                $players[$id]['red'] += $red ? 1 : 0;
                $players[$id]['club_id'] = (int) $sheet->club_id;
                $clubCards[$sheet->club_id]['yellow'] += min(1, (int) ($p['yc'] ?? 0));
                $clubCards[$sheet->club_id]['red'] += $red ? 1 : 0;
            }
        }
        $names = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.id', array_keys($players))->pluck('master_players.name', 'players.id');
        $list = function (string $key, string $then) use ($players, $names, $card, $top) {
            $rows = array_filter($players, fn ($p) => $p[$key] > 0);
            uksort($rows, fn ($a, $b) => [$rows[$b][$key], $rows[$b][$then], $a] <=> [$rows[$a][$key], $rows[$a][$then], $b]);

            return array_values(array_map(fn ($id) => ['player' => ['id' => $id, 'name' => $names[$id] ?? ''], 'club' => $card($rows[$id]['club_id']),
                $key => $rows[$id][$key], $then => $rows[$id][$then]], array_slice(array_keys($rows), 0, $top)));
        };
        $clubs = array_map(fn ($id) => ['club' => $card($id)] + $clubCards[$id], array_keys($clubCards));
        usort($clubs, fn ($a, $b) => [$b['red'], $b['yellow']] <=> [$a['red'], $a['yellow']]);

        return [
            'scorers' => $list('goals', 'assists'),
            'assists' => $list('assists', 'goals'),
            'discipline' => ['players' => $list('red', 'yellow'), 'bookings' => $list('yellow', 'red'), 'clubs' => $clubs],
        ];
    }

    /** Each club's buying and selling this season, from the moves (the pool, the bots and the coaches). */
    private static function finance(int $seasonId, array $ids, \Closure $card): array
    {
        $moves = DB::table('player_moves')->where('season_id', $seasonId)->get(['from_club_id', 'to_club_id', 'price']);
        $out = [];
        foreach ($ids as $id) {
            $in = $moves->where('to_club_id', $id);
            $gone = $moves->where('from_club_id', $id);
            $out[] = ['club' => $card($id), 'bought' => (int) $in->sum('price'), 'bought_count' => $in->count(),
                'sold' => (int) $gone->sum('price'), 'sold_count' => $gone->count(), 'net' => (int) $gone->sum('price') - (int) $in->sum('price')];
        }
        usort($out, fn ($a, $b) => $b['bought'] <=> $a['bought']);

        return $out;
    }

    /** The clubs by the market value of their whole squad. */
    private static function value(int $leagueId, \Closure $card): array
    {
        return DB::table('players')->where('league_id', $leagueId)->whereNotNull('club_id')->groupBy('club_id')
            ->selectRaw('club_id, sum(value) as total, count(*) as players')->orderByDesc('total')->get()
            ->values()->map(fn ($r, $i) => ['position' => $i + 1, 'club' => $card((int) $r->club_id), 'value' => (int) $r->total, 'players' => (int) $r->players])->all();
    }

    /** The runs of results in every competition: the current one, and each club's longest wins, draws and defeats. */
    private static function streaks($matches, array $ids, \Closure $card): array
    {
        $runs = [];
        foreach ($ids as $id) {
            $runs[$id] = ['current' => null, 'best' => ['W' => 0, 'D' => 0, 'L' => 0], 'form' => []];
        }
        foreach ($matches as $m) {
            foreach ([[$m->home_id, $m->home_goals <=> $m->away_goals], [$m->away_id, $m->away_goals <=> $m->home_goals]] as [$id, $r]) {
                if (! isset($runs[$id])) {
                    continue;
                }
                $k = [1 => 'W', 0 => 'D', -1 => 'L'][$r];
                $cur = $runs[$id]['current'];
                $runs[$id]['current'] = $cur && $cur['kind'] === $k ? ['kind' => $k, 'length' => $cur['length'] + 1] : ['kind' => $k, 'length' => 1];
                $runs[$id]['best'][$k] = max($runs[$id]['best'][$k], $runs[$id]['current']['length']);
                $runs[$id]['form'] = array_slice([...$runs[$id]['form'], $k], -5);
            }
        }
        $out = array_map(fn ($id) => ['club' => $card($id)] + $runs[$id], $ids);
        $winning = fn ($r) => ($r['current']['kind'] ?? '') === 'W' ? $r['current']['length'] : 0;
        usort($out, fn ($a, $b) => [$b['best']['W'], $winning($b)] <=> [$a['best']['W'], $winning($a)]);

        return $out;
    }
}
