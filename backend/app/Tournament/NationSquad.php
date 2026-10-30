<?php

namespace App\Tournament;

use App\Data\Nations;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 27] The national teams. A country is a team when the data has config('game.tournaments.nation_min_players')
 * of its players with a goalkeeper among them; its strength is its best 18's average, as an imported club's. Its squad
 * in a tournament is its best nation_squad players (nation_keepers of them goalkeepers) not already playing for a club
 * of the same tournament.
 */
class NationSquad
{
    public const SOURCE = 'nation';

    public const LEAGUE_NAME = 'National Teams';

    /** Every country's players, by the team's name: [name => list of {id, overall, line}], best first. */
    public static function players(string $version): array
    {
        $by = [];
        foreach (DB::table('master_players')->join('master_clubs', 'master_clubs.id', '=', 'master_players.master_club_id')
            ->where('master_players.data_version', $version)->where('master_clubs.source', '!=', self::SOURCE)->whereNotNull('master_players.nationality')
            ->orderByDesc('master_players.overall')->orderBy('master_players.id')
            ->get(['master_players.id', 'master_players.overall', 'master_players.line', 'master_players.nationality']) as $p) {
            if ($name = Nations::canonical($p->nationality)) {
                $by[$name][] = $p;
            }
        }

        return $by;
    }

    public static function playable(array $players): bool
    {
        return count($players) >= (int) config('game.tournaments.nation_min_players')
            && collect($players)->contains(fn ($p) => $p->line === 'gk');
    }

    /** @return array{0: int, 1: int} made, updated */
    public static function sync(string $version): array
    {
        $made = $updated = 0;
        $now = GameClock::now();
        $there = DB::table('master_clubs')->where('data_version', $version)->where('source', self::SOURCE)->pluck('id', 'name');
        foreach (self::players($version) as $name => $players) {
            if (! self::playable($players)) {
                continue;
            }
            $best = array_slice(array_column($players, 'overall'), 0, 18);
            $info = Nations::info($name);
            $row = ['strength_cp' => intdiv(array_sum($best) * 100, count($best)), 'updated_at' => $now];
            if (isset($there[$name])) {
                $updated += DB::table('master_clubs')->where('id', $there[$name])->update($row);

                continue;
            }
            // A club of the same name (none today) keeps it: the country is skipped rather than made twice.
            $made += DB::table('master_clubs')->insertOrIgnore($row + ['data_version' => $version, 'source' => self::SOURCE, 'name' => $name,
                'code' => $info['code'], 'league_name' => self::LEAGUE_NAME, 'nation' => $name, 'confederation' => $info['confederation'],
                'color_primary' => $info['colors'][0], 'color_secondary' => $info['colors'][1], 'created_at' => $now]);
        }

        return [$made, $updated];
    }

    /**
     * The squad of one national team: master player ids, goalkeepers first, without those taken.
     *
     * @param  array<int, true>  $taken  master player ids already in the tournament
     */
    public static function pick(string $nation, string $version, array $taken): array
    {
        $rows = DB::table('master_players')->join('master_clubs', 'master_clubs.id', '=', 'master_players.master_club_id')
            ->where('master_players.data_version', $version)->where('master_clubs.source', '!=', self::SOURCE)
            ->whereIn('master_players.nationality', Nations::spellings($nation))
            ->orderByDesc('master_players.overall')->orderBy('master_players.id')->get(['master_players.id', 'master_players.line']);
        $rows = $rows->reject(fn ($p) => isset($taken[$p->id]));
        $c = config('game.tournaments');
        $keepers = $rows->where('line', 'gk')->take($c['nation_keepers']);
        $field = $rows->where('line', '!=', 'gk')->take($c['nation_squad'] - $keepers->count());

        return $keepers->concat($field)->pluck('id')->map(fn ($id) => (int) $id)->all();
    }
}
