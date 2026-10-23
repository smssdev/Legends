<?php

namespace App\League;

use App\Engine\MatchSetup;
use App\Models\Club;
use App\Simulator\MatchFactory;
use App\Training\Training;
use Illuminate\Support\Facades\DB;

/**
 * A league fixture as an engine state [PLAN 2.12]: both frozen sheets from the lock (formation and its own
 * slots, the eleven, the bench, the takers and the tactics), each player's fitness, the referee drawn
 * before the match, and a config snapshot taken now, so changing config/game.php never changes a match
 * that has started or its replay.
 */
class LeagueMatch
{
    public const REFEREE = ['lenient' => 0, 'medium' => 1, 'strict' => 2];

    public static function state(object $fixture, int $seed): array
    {
        $sheets = DB::table('fixture_sheets')->where('fixture_id', $fixture->id)->get()->keyBy('club_id');
        $side = fn (int $clubId) => self::side(Club::findOrFail($clubId), $sheets[$clubId]);

        return self::withFitness(MatchSetup::build($side($fixture->home_id), $side($fixture->away_id), [
            'seed' => $seed,
            'competition' => $fixture->competition,
            'referee' => self::REFEREE[$fixture->referee_strictness ?? 'medium'],
            'venue' => 'home',
        ], MatchFactory::snapshot()));
    }

    private static function side(Club $club, object $sheet): array
    {
        $takers = json_decode($sheet->takers, true);

        return [
            'club' => [
                'id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'league' => null,
                'primary' => $club->color_primary, 'secondary' => $club->color_secondary, 'strength' => (int) $club->strength_snapshot,
            ],
            // The squad in the shape MatchSetup::player reads, with this league's own numbers.
            'squad' => DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->where('players.club_id', $club->id)
                ->select('master_players.*', 'players.id', 'players.overall', 'players.training_bonus', 'players.fitness')->orderBy('players.id')->get()
                ->map(fn ($r) => Training::boosted((array) $r))->all(),
            'formation' => $sheet->formation,
            'slots' => json_decode($sheet->slots, true),
            'starters' => json_decode($sheet->starters, true),
            'bench' => json_decode($sheet->bench, true),
            'takers' => array_filter(array_map(fn ($t) => $t['player_id'] ?? null, $takers)),
            'tactics' => json_decode($sheet->tactics, true),
        ];
    }

    /** Each player starts the match with his fitness (MatchSetup starts everyone fresh). */
    private static function withFitness(array $state): array
    {
        foreach (['home', 'away'] as $side) {
            $ids = array_column($state['teams'][$side]['players'], 'id');
            $fitness = DB::table('players')->whereIn('id', $ids)->pluck('fitness', 'id');
            foreach ($state['teams'][$side]['players'] as &$p) {
                $p['fit'] = (int) ($fitness[$p['id']] ?? 100) * 100;
            }
            unset($p);
        }

        return $state;
    }
}
