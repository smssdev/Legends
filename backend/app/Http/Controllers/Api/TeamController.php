<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\FormationBook;
use App\League\TeamSheet;
use App\Models\Club;
use App\Models\League;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * My club in a league [PLAN 2.15, 2.16]: the squad with each player's card, the lineup and its editor's
 * choices (the 24 formations and up to 3 of my own), and the captain and set-piece takers.
 */
class TeamController extends Controller
{
    /** The 24 formations, the same for everyone. */
    public function formations(): JsonResponse
    {
        return response()->json([
            'formations' => collect(FormationBook::names())->map(fn ($n) => $this->formation($n, FormationBook::label($n), FormationBook::slots($n))),
            'limits' => FormationBook::LIMITS,
            'grid' => ['rows' => array_keys(FormationBook::ROWS), 'columns' => array_keys(FormationBook::COLUMNS)],
        ]);
    }

    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $lineup = TeamSheet::current($club);
        $starters = array_flip(array_filter($lineup['starters']));
        $bench = array_flip($lineup['bench']);
        $players = $this->players($club)->map(fn ($p) => $p + ['role' => isset($starters[$p['id']]) ? 'starter' : (isset($bench[$p['id']]) ? 'bench' : 'reserve')]);

        return response()->json([
            'club' => ['id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'strength_cp' => (int) $club->strength_snapshot,
                'balance' => (int) $club->balance, 'crest_url' => url("/api/v1/data/clubs/{$club->master_club_id}/crest.svg")],
            'squad_value' => (int) $players->sum('value'),
            'players' => $players->values(),
            'lineup' => $this->lineup($lineup),
            'takers' => TeamSheet::takers($club, $lineup),
            'custom_formations' => collect(TeamSheet::customs($club))->map(fn ($c) => $this->formation('custom:'.$c['number'], $c['name'], FormationBook::custom($c['cells'])) + ['number' => $c['number'], 'cells' => $c['cells']]),
        ]);
    }

    /** "تحسين": the best lineup now, not saved, for the editor to show before "حفظ". */
    public function suggestion(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);

        return response()->json(['lineup' => $this->lineup(TeamSheet::best($club) + ['auto' => true])]);
    }

    public function saveLineup(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate([
            'formation' => ['required', 'string', 'max:16'],
            'starters' => ['required', 'array'],
            'starters.*' => ['nullable', 'integer'],
            'bench' => ['present', 'array'],
            'bench.*' => ['integer'],
        ]);
        TeamSheet::save($club, $data['formation'], array_map(fn ($v) => $v === null ? null : (int) $v, $data['starters']), array_map('intval', $data['bench']));

        return $this->show($request, $league);
    }

    /** Go back to the automatic lineup ("تحسين" kept up to date for me). */
    public function resetLineup(Request $request, League $league): JsonResponse
    {
        DB::table('lineups')->where('club_id', $this->club($request->user(), $league)->id)->delete();

        return $this->show($request, $league);
    }

    public function saveFormation(Request $request, League $league, int $number): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:30'],
            'cells' => ['required', 'array'],
            'cells.*' => ['array', 'size:2'],
            'cells.*.0' => ['required', Rule::in(array_keys(FormationBook::ROWS))],
            'cells.*.1' => ['required', 'integer', 'between:1,5'],
        ]);
        TeamSheet::saveCustom($club, $number, trim($data['name']), array_map(fn ($c) => [$c[0], (int) $c[1]], $data['cells']));

        return $this->show($request, $league);
    }

    public function saveTakers(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate(collect(['captain', 'penalty', 'free_kick', 'corner'])->mapWithKeys(fn ($r) => [$r => ['nullable', 'integer']])->all());
        TeamSheet::saveTakers($club, $data);

        return $this->show($request, $league);
    }

    /** My club in this league; 403 without one. */
    private function club(User $user, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $user->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }

    /** Each player's card: attributes, potential, fitness, value, and whether he can play [PLAN 2.15]. */
    private function players(Club $club)
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $club->id)
            ->select('players.*', 'master_players.name', 'master_players.position', 'master_players.alt_positions', 'master_players.line', 'master_players.age',
                'master_players.nationality', 'master_players.preferred_foot', 'master_players.potential',
                'master_players.pac', 'master_players.sho', 'master_players.pas', 'master_players.dri', 'master_players.def', 'master_players.phy',
                'master_players.gk_diving', 'master_players.gk_handling', 'master_players.gk_kicking', 'master_players.gk_positioning', 'master_players.gk_reflexes')
            ->orderByRaw("case master_players.line when 'gk' then 0 when 'def' then 1 when 'mid' then 2 else 3 end")->orderByDesc('players.overall')->get()
            ->map(fn ($p) => [
                'id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'alt_positions' => $p->alt_positions, 'line' => $p->line,
                'age' => $p->age, 'nationality' => $p->nationality, 'foot' => $p->preferred_foot,
                'overall' => $p->overall, 'potential' => $p->potential, 'value' => (int) $p->value, 'fitness' => $p->fitness,
                'injured_matches' => $p->injured_matches, 'suspended_matches' => $p->suspended_matches,
                'available' => $p->injured_matches === 0 && $p->suspended_matches === 0,
                'attributes' => $p->line === 'gk'
                    ? ['diving' => $p->gk_diving, 'handling' => $p->gk_handling, 'kicking' => $p->gk_kicking, 'positioning' => $p->gk_positioning, 'reflexes' => $p->gk_reflexes]
                    : ['pac' => $p->pac, 'sho' => $p->sho, 'pas' => $p->pas, 'dri' => $p->dri, 'def' => $p->def, 'phy' => $p->phy],
            ]);
    }

    private function lineup(array $l): array
    {
        return ['formation' => $l['formation'], 'auto' => $l['auto'], 'slots' => $l['slots'], 'starters' => $l['starters'], 'bench' => $l['bench'],
            'lines' => FormationBook::lines($l['slots'])];
    }

    private function formation(string $name, string $label, array $slots): array
    {
        return ['name' => $name, 'label' => $label, 'slots' => $slots, 'lines' => FormationBook::lines($slots)];
    }
}
