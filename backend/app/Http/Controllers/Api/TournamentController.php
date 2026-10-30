<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\CupBracket;
use App\League\LeagueTiers;
use App\League\Standings;
use App\Models\Club;
use App\Models\League;
use App\Rules\NotJunk;
use App\Support\GameClock;
use App\Tournament\NationSquad;
use App\Tournament\TournamentCatalog;
use App\Tournament\TournamentFactory;
use App\Tournament\TournamentPlan;
use App\Tournament\TournamentScheduler;
use App\Tournament\TournamentStage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/**
 * [Sprint 27] Tournaments: the catalog to make one from (templates, national teams, clubs), making it, its page (the
 * groups' tables and the bracket), and its draw, which every signed-in player may watch live or replay.
 */
class TournamentController extends Controller
{
    /** The tournaments on the game, newest first: those waiting for their draw first. */
    public function index(): JsonResponse
    {
        $rows = League::where('kind', 'tournament')->with('owner')->orderByRaw('drawn_at is null desc')->orderByDesc('id')->limit(40)->get();

        return response()->json(['tournaments' => $rows->map(fn (League $l) => $this->summary($l))->values()]);
    }

    public function catalog(): JsonResponse
    {
        $c = config('game.tournaments');

        return response()->json([
            'templates' => collect(array_keys($c['templates']))->map(fn ($k) => TournamentCatalog::suggest($k))->values(),
            'nations' => TournamentCatalog::nations(),
            'missing' => TournamentCatalog::missing(),
            'limits' => ['min_teams' => $c['min_teams'], 'max_teams' => $c['max_teams'], 'group_counts' => $c['group_counts'], 'advance' => $c['advance'],
                // [X65] Its price: this many coins for each team.
                'coins_per_team' => (int) config('game.league.custom_coins_per_club')],
        ]);
    }

    /** Clubs to add, by name or by league (not the national teams: they are in the catalog). */
    public function clubs(Request $request): JsonResponse
    {
        $data = $request->validate(['q' => ['nullable', 'string', 'max:60'], 'league' => ['nullable', 'string', 'max:80'], 'ids' => ['nullable', 'string', 'max:400']]);
        $rows = DB::table('master_clubs')->where('data_version', DataController::version())->where('source', '!=', NationSquad::SOURCE)
            ->when($data['q'] ?? null, fn ($w, $q) => $w->whereLike('name', '%'.$q.'%'))
            ->when($data['league'] ?? null, fn ($w, $l) => $w->where('league_name', $l))
            ->when($data['ids'] ?? null, fn ($w, $ids) => $w->whereIn('id', array_map('intval', explode(',', $ids))))
            ->orderByDesc('strength_cp')->orderBy('id')->limit(60)->get();

        return response()->json(['clubs' => $rows->map(fn ($m) => TournamentCatalog::card($m))->values()]);
    }

    public function store(Request $request): JsonResponse
    {
        $c = config('game.tournaments');
        $l = config('game.league');
        $dev = ! app()->isProduction() && $request->boolean('is_dev');
        $data = $request->validate([
            'name' => ['nullable', 'string', 'max:60', new NotJunk],
            'template' => ['required', Rule::in(array_keys($c['templates']))],
            'teams' => ['required', 'array', 'min:'.$c['min_teams'], 'max:'.$c['max_teams']],
            'teams.*' => ['integer', 'distinct'],
            'format' => ['required', Rule::in(TournamentPlan::FORMATS)],
            'group_count' => ['nullable', 'integer'],
            'advance_per_group' => ['nullable', 'integer'],
            'legs' => ['nullable', 'integer', 'in:1,2'],
            'rounds_per_day' => ['sometimes', 'integer', 'between:1,'.($dev ? 2 : $l['rounds_per_day'][1])],
            'round_times' => ['sometimes', 'array', 'size:'.(int) $request->input('rounds_per_day', 1)],
            'round_times.*' => ['date_format:H:i', 'distinct'],
            'prep_days' => ['sometimes', 'integer', 'between:'.($dev ? 0 : 1).','.max($l['prep_days_options'])],
            'starts_at' => ['required', 'date'],
            'draw_at' => ['nullable', 'date'],
            'starting_budget' => ['sometimes', 'integer', 'between:'.config('game.economy.starting_budget_min').','.config('game.economy.starting_budget_max')],
            'club_id' => ['nullable', 'integer'],
            'timezone' => ['sometimes', 'nullable', 'string', 'max:64'],
            'is_dev' => ['sometimes', 'boolean'],
        ]);
        $at = Carbon::parse($data['starts_at'])->utc()->startOfMinute();
        $now = GameClock::now();
        if ($at->lt($now->copy()->subMinute()) || $at->gt($now->copy()->addDays($l['starts_within_days']))) {
            throw ValidationException::withMessages(['starts_at' => __('اختر موعد البدء من الآن حتى :n أيام.', ['n' => $l['starts_within_days']])]);
        }
        $data['starts_at'] = $at->max($now->copy()->startOfMinute());
        $free = LeagueTiers::free('Tournament', $data['timezone'] ?? null);
        $data += ['rounds_per_day' => 1, 'round_times' => $free['round_times'], 'prep_days' => $dev ? 0 : 1, 'starting_budget' => $free['starting_budget']];
        if (isset($data['round_times']) && count($data['round_times']) !== $data['rounds_per_day']) {
            $data['rounds_per_day'] = count($data['round_times']);
        }
        $data['is_dev'] = $dev;
        $league = TournamentFactory::create($request->user(), $data);

        return response()->json(['tournament' => $this->summary($league->load('owner'))], 201);
    }

    /** The tournament's page: its teams, the groups' tables, the league table and the bracket. */
    public function show(Request $request, League $league): JsonResponse
    {
        abort_unless($league->kind === 'tournament', 404);
        $season = $league->season;
        $cards = $this->cards($league);
        $row = fn (array $r) => ['club' => $cards[$r['id']] ?? null, 'played' => $r['p'], 'won' => $r['w'], 'drawn' => $r['d'], 'lost' => $r['l'],
            'goals_for' => $r['gf'], 'goals_against' => $r['ga'], 'points' => $r['pts']];
        $groups = [];
        if ($league->format === 'groups' && $league->drawn_at) {
            foreach (TournamentStage::tables($season->id, $league->id) as $g => $rows) {
                $groups[] = ['group' => TournamentPlan::letter($g), 'rows' => array_map($row, $rows)];
            }
        }
        $ties = DB::table('cup_ties')->join('fixtures', 'fixtures.id', '=', 'cup_ties.fixture_id')->where('cup_ties.season_id', $season->id)
            ->orderBy('fixtures.round')->orderBy('cup_ties.slot')
            ->get(['cup_ties.*', 'fixtures.scheduled_at', 'fixtures.status', 'fixtures.home_goals', 'fixtures.away_goals', 'fixtures.round']);

        return response()->json(['tournament' => $this->summary($league->load('owner')) + [
            'teams' => array_values($cards),
            'groups' => $groups,
            'table' => $league->format === 'league' ? array_map($row, Standings::table($season->id)) : [],
            'bracket' => $ties->groupBy('stage')->map(fn ($list, $stage) => ['stage' => $stage, 'ties' => $list->map(fn ($t) => [
                'slot' => (int) $t->slot, 'home' => $cards[$t->home_id] ?? null, 'away' => $cards[$t->away_id] ?? null,
                'home_from' => $t->home_from, 'away_from' => $t->away_from, 'winner_id' => $t->winner_id,
                'score' => $t->status === 'finished' ? [(int) $t->home_goals, (int) $t->away_goals] : null,
                'at' => Carbon::parse($t->scheduled_at, 'UTC')->toIso8601ZuluString(), 'fixture_id' => (int) $t->fixture_id,
            ])->values()])->values(),
        ]]);
    }

    /**
     * The draw, for anyone signed in: before it its time and announced hash; after, every ball in order with its team,
     * replayed on the shared clock (one every reveal_ms from drawn_at), so everyone sees the same ball at the same moment.
     */
    public function draw(Request $request, League $league): JsonResponse
    {
        abort_unless($league->kind === 'tournament', 404);
        $cards = $league->drawn_at ? $this->cards($league) : [];
        $steps = $league->drawn_at ? array_map(fn ($s) => ['club' => $cards[$s['club']] ?? null] + $s, TournamentScheduler::plan($league)['steps']) : [];
        $user = $request->user();

        return response()->json($this->summary($league->load('owner')) + [
            'commit' => $league->draw_commit,
            'seed' => $league->drawn_at ? (int) $league->draw_seed : null,
            'reveal_ms' => (int) config('game.tournaments.reveal_ms'),
            'server_now' => GameClock::nowMs(),
            'is_owner' => $league->isOwner($user),
            'can_schedule' => $league->isOwner($user) && ! $league->settings_locked_at && ! $league->drawn_at,
            'pots' => $league->format === 'groups' ? (int) ceil($league->team_count / max(1, (int) $league->group_count)) : 0,
            'stages' => $league->format === 'knockout' ? CupBracket::stages((int) $league->team_count) : [],
            'steps' => $steps,
        ]);
    }

    private function summary(League $l): array
    {
        return ['id' => $l->id, 'name' => $l->name, 'code' => $l->code, 'template' => $l->tournament_template, 'format' => $l->format,
            'group_count' => $l->group_count ? (int) $l->group_count : null, 'advance_per_group' => $l->advance_per_group ? (int) $l->advance_per_group : null,
            'legs' => $l->legs ? (int) $l->legs : null, 'team_count' => (int) $l->team_count, 'status' => $l->status,
            'owner' => $l->owner ? ['id' => $l->owner->id, 'name' => $l->owner->name] : null,
            'starts_at' => $l->starts_at->toIso8601ZuluString(), 'draw_at' => $l->draw_at?->toIso8601ZuluString(),
            'drawn_at' => $l->drawn_at?->toIso8601ZuluString(), 'coaches' => Club::where('league_id', $l->id)->whereNotNull('user_id')->count()];
    }

    /** Every team of the tournament as the screens show it, by id. */
    private function cards(League $league): array
    {
        return Club::where('league_id', $league->id)->with('user')->get()->mapWithKeys(fn (Club $c) => [$c->id => [
            'id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'strength_cp' => (int) $c->strength_snapshot, 'group' => $c->group_no ? TournamentPlan::letter((int) $c->group_no) : null,
            'colors' => [$c->color_primary, $c->color_secondary], 'crest_url' => url("/api/v1/data/clubs/{$c->master_club_id}/crest.svg"), 'coach' => $c->user?->name,
        ]])->all();
    }
}
