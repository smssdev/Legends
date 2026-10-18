<?php

namespace App\Http\Controllers\Api;

use App\Engine\Formations;
use App\Http\Controllers\Controller;
use App\Models\MasterClub;
use App\Models\SimMatch;
use App\Simulator\Simulator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** Simulator API (docs/MATCH_VIEW.md 8, docs/api/openapi.yaml). */
class SimulatorController extends Controller
{
    public function __construct(private Simulator $sim) {}

    public function leagues()
    {
        return DB::table('master_clubs')->select('league_name as name', DB::raw('count(*) as clubs'), DB::raw('max(strength_cp) as top'))
            ->groupBy('league_name')->orderByDesc('top')->get();
    }

    public function clubs(Request $request)
    {
        $data = $request->validate(['q' => 'nullable|string|max:60', 'league' => 'nullable|string|max:80']);

        return MasterClub::query()
            ->when($data['q'] ?? null, fn ($q, $term) => $q->where('name', 'like', '%'.$term.'%'))
            ->when($data['league'] ?? null, fn ($q, $league) => $q->where('league_name', $league))
            ->orderByDesc('strength_cp')->limit(60)
            ->get(['id', 'name', 'code', 'league_name', 'strength_cp', 'color_primary', 'color_secondary']);
    }

    public function club(MasterClub $club)
    {
        return $this->sim->squad($club);
    }

    public function store(Request $request)
    {
        $tactics = ['nullable', 'array'];
        $data = $request->validate([
            'home_id' => 'required|integer|exists:master_clubs,id',
            'away_id' => 'required|integer|exists:master_clubs,id|different:home_id',
            'seed' => 'nullable|integer|min:1|max:999999999',
            'competition' => 'nullable|in:league,cup',
            'referee' => 'nullable|integer|between:0,2',
            'venue' => 'nullable|in:home,neutral',
            'mode' => 'nullable|in:solo,live',
            'control.home' => 'nullable|in:me,cpu',
            'control.away' => 'nullable|in:me,cpu',
            'home.formation' => ['nullable', Rule::in(Formations::names())],
            'away.formation' => ['nullable', Rule::in(Formations::names())],
            'home.tactics' => $tactics,
            'away.tactics' => $tactics,
        ]);

        return response()->json($this->sim->view($this->sim->create($data)), 201);
    }

    public function show(SimMatch $match)
    {
        return $this->sim->view($match);
    }

    public function order(Request $request, SimMatch $match)
    {
        $data = $request->validate([
            'type' => 'required|in:sub,tactics,formation',
            'team' => 'required|in:home,away',
            'out' => 'required_if:type,sub|integer',
            'in' => 'required_if:type,sub|integer',
            'tactics' => 'required_if:type,tactics|array',
            'formation' => ['required_if:type,formation', 'nullable', Rule::in(Formations::names())],
            'idempotency_key' => 'required|string|max:64',
        ]);
        abort_if($match->state['finished'], 409, 'انتهت المباراة.');

        $order = array_filter([
            'type' => $data['type'], 'team' => $data['team'], 'out' => $data['out'] ?? null, 'in' => $data['in'] ?? null,
            'tactics' => $data['tactics'] ?? null, 'formation' => $data['formation'] ?? null,
        ], fn ($v) => $v !== null) + ['key' => $data['idempotency_key']];
        $result = $this->sim->order($match, $order);

        return response()->json($result, $result['duplicate'] ? 200 : 202);
    }

    public function ticks(Request $request, SimMatch $match)
    {
        $data = $request->validate(['count' => 'nullable|integer|min:1|max:200']);
        abort_if($match->live !== null, 409, 'المباراة المباشرة يديرها الخادم.');

        return ['ticks' => $this->sim->advance($match, (int) ($data['count'] ?? 1))];
    }

    public function start(SimMatch $match)
    {
        abort_if($match->live === null, 409, 'هذه ليست مباراة مباشرة.');
        $this->sim->start($match);

        return $this->sim->sync($match, $match->state['tick']);
    }

    public function live(Request $request, SimMatch $match)
    {
        abort_if($match->live === null, 409, 'هذه ليست مباراة مباشرة.');
        $since = (int) ($request->validate(['since' => 'nullable|integer|min:0'])['since'] ?? 0);

        return $this->sim->sync($match, $since);
    }

    public function report(Request $request, SimMatch $match)
    {
        $side = $request->validate(['side' => 'nullable|in:home,away'])['side'] ?? 'home';
        abort_unless($match->state['finished'], 409, 'المباراة لم تنته بعد.');

        return $this->sim->report($match, $side);
    }
}
