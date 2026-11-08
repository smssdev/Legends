<?php

namespace App\League;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 48 T1] The squad's season for the team screen (the owner's screenshots, 2026-11-08): each player's goals,
 * assists, matches and his rating in each league round (hundredths: 750 is 7.5), from the finished matches' sheets
 * (match_stats); and the league's transfers this season, newest first. Nothing hidden: no tactic, only what the
 * league's table and statistics centre already show.
 */
class SquadSeason
{
    public static function of(int $clubId, int $leagueId, int $seasonId): array
    {
        $matches = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
            ->where('fixtures.season_id', $seasonId)->where('fixtures.status', 'finished')->where('fixtures.is_bye', false)
            ->where(fn ($q) => $q->where('fixtures.home_id', $clubId)->orWhere('fixtures.away_id', $clubId))
            ->get(['matches.id', 'fixtures.round', 'fixtures.competition'])->keyBy('id');

        $players = [];
        $rounds = 0;
        $sheets = DB::table('match_stats')->whereIn('match_id', $matches->keys()->all())->where('club_id', $clubId)->get(['match_id', 'players']);
        foreach ($sheets as $sheet) {
            $m = $matches[$sheet->match_id];
            $league = $m->competition === 'league';
            $rounds = $league ? max($rounds, (int) $m->round) : $rounds;
            foreach (json_decode($sheet->players, true) ?? [] as $p) {
                if (! ($p['played'] ?? false)) {
                    continue;
                }
                $id = (int) $p['id'];
                $players[$id] ??= ['goals' => 0, 'assists' => 0, 'played' => 0, 'ratings' => []];
                $players[$id]['goals'] += (int) ($p['goals'] ?? 0);
                $players[$id]['assists'] += (int) ($p['assists'] ?? 0);
                $players[$id]['played']++;
                if ($league) {
                    $players[$id]['ratings'][(string) $m->round] = (int) ($p['rating'] ?? 600);
                }
            }
        }
        foreach ($players as &$p) {
            $p['average'] = $p['ratings'] ? intdiv(array_sum($p['ratings']), count($p['ratings'])) : null;
            $p['ratings'] = (object) $p['ratings'];
        }
        unset($p);

        return ['rounds' => $rounds, 'players' => (object) $players, 'transfers' => self::transfers($leagueId, $seasonId)];
    }

    /** The league's moves this season: who, his position, from and to which club, the price and his value now. */
    private static function transfers(int $leagueId, int $seasonId, int $limit = 60): array
    {
        $clubs = DB::table('clubs')->where('league_id', $leagueId)->pluck('name', 'id');

        return DB::table('player_moves')->join('players', 'players.id', '=', 'player_moves.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('player_moves.season_id', $seasonId)->orderByDesc('player_moves.id')->limit($limit)
            ->get(['player_moves.id', 'player_moves.player_id', 'master_players.name', 'master_players.position', 'player_moves.from_club_id',
                'player_moves.to_club_id', 'player_moves.price', 'players.value', 'player_moves.created_at'])
            ->map(fn ($r) => ['id' => (int) $r->id, 'player_id' => (int) $r->player_id, 'name' => $r->name, 'position' => $r->position,
                'from' => $r->from_club_id ? ($clubs[$r->from_club_id] ?? null) : null, 'to' => $r->to_club_id ? ($clubs[$r->to_club_id] ?? null) : null,
                'price' => (int) $r->price, 'value' => (int) $r->value, 'at' => Carbon::parse($r->created_at, 'UTC')->toIso8601ZuluString()])
            ->all();
    }
}
