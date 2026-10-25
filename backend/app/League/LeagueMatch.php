<?php

namespace App\League;

use App\Engine\MatchSetup;
use App\Models\Club;
use App\Simulator\MatchFactory;
use App\Stadium\Stadium;
use App\Staff\Specialists;
use App\Training\SecretTraining;
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
        // The bribes face the VAR first: a side caught loses morale before it is measured [X28].
        $bribed = Integrity::kickOff($fixture, $seed);
        $side = fn (int $clubId) => self::side(Club::findOrFail($clubId), $sheets[$clubId])
            + ['morale' => Morale::forMatch($fixture, $clubId === (int) $fixture->home_id ? 'home' : 'away'),
                'bribed' => $bribed[$clubId === (int) $fixture->home_id ? 'home' : 'away']];

        $frozen = $sheets->flatMap(fn ($s) => $s->squad ? json_decode($s->squad, true) : [])->all();

        return self::withFitness(MatchSetup::build($side($fixture->home_id), $side($fixture->away_id), [
            'seed' => $seed,
            // The alliance tournament is a knockout like the cup [X27].
            'competition' => $fixture->competition === 'alliance' ? 'cup' : $fixture->competition,
            'referee' => self::REFEREE[$fixture->referee_strictness ?? 'medium'],
            'venue' => 'home',
            'pitch' => Stadium::stage($fixture->home_id, 'pitch'),
        ], MatchFactory::snapshot()), $frozen);
    }

    private static function side(Club $club, object $sheet): array
    {
        $takers = json_decode($sheet->takers, true);
        // Secret training: one line, this match only [docs/features/secret-training.md].
        $boosts = SecretTraining::boosts($club->id, $sheet->fixture_id);
        // The keeper coach [docs/features/specialists.md].
        if ($boost = Specialists::effect($club->id, 'keeper_coach', 'keeper_coach_boost')) {
            $boosts['gk'] = ($boosts['gk'] ?? 0) + $boost;
        }

        return [
            'club' => [
                'id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'league' => null,
                'primary' => $club->color_primary, 'secondary' => $club->color_secondary, 'strength' => (int) $club->strength_snapshot,
            ],
            // The squad in the shape MatchSetup::player reads, with this league's own numbers: as frozen at the lock
            // (X31; a sheet locked before that freeze reads the squad as it is now).
            'squad' => array_map(fn ($r) => Training::boosted($r, $boosts[$r['line']] ?? 0),
                $sheet->squad ? json_decode($sheet->squad, true) : self::squadRows($club->id)),
            'formation' => $sheet->formation,
            'slots' => json_decode($sheet->slots, true),
            'starters' => json_decode($sheet->starters, true),
            'bench' => json_decode($sheet->bench, true),
            'takers' => array_filter(array_map(fn ($t) => $t['player_id'] ?? null, $takers)),
            'tactics' => json_decode($sheet->tactics, true),
            // The eleven's chemistry on the frozen sheet [X22].
            'chem' => Chemistry::of($club->id, json_decode($sheet->starters, true), json_decode($sheet->slots, true))['score'],
        ];
    }

    /** A club's squad rows as the match reads them, the same at the lock (frozen) and at kick-off. */
    public static function squadRows(int $clubId): array
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $clubId)
            ->select('master_players.*', 'players.id', 'players.overall', 'players.training_bonus', 'players.fitness')->orderBy('players.id')->get()
            ->map(fn ($r) => (array) $r)->all();
    }

    /** Each player starts the match with his fitness (MatchSetup starts everyone fresh): as frozen at the lock [X31]. */
    private static function withFitness(array $state, array $frozen = []): array
    {
        foreach (['home', 'away'] as $side) {
            $ids = array_column($state['teams'][$side]['players'], 'id');
            $fitness = DB::table('players')->whereIn('id', $ids)->pluck('fitness', 'id')->all();
            foreach ($frozen as $row) {
                if (in_array((int) $row['id'], $ids, true)) {
                    $fitness[(int) $row['id']] = (int) $row['fitness'];
                }
            }
            foreach ($state['teams'][$side]['players'] as &$p) {
                $p['fit'] = (int) ($fitness[$p['id']] ?? 100) * 100;
            }
            unset($p);
        }

        return $state;
    }
}
