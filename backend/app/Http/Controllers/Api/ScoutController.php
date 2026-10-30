<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Market\Market;
use App\Market\Scout;
use App\Models\Club;
use App\Models\League;
use App\Support\Nation;
use App\Wallet\Finish;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** The scout [docs/features/scout.md, Sprint 26]: the criteria, the search under way, and the reports. */
class ScoutController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $requests = DB::table('scout_requests')->where('club_id', $club->id)->orderByDesc('id')->limit(10)->get();
        $version = DB::table('master_players')->max('data_version');

        return response()->json([
            'cost' => Scout::cost($league->id),
            'hours' => intdiv((int) config('game.scout.hours') * max(1, (int) $league->timer_scale), 10000),
            'balance' => (int) $club->balance,
            'options' => [
                'leagues' => DB::table('master_clubs')->where('data_version', $version)->where('source', '!=', 'nation')->distinct()->orderBy('league_name')->pluck('league_name'),
                'nationalities' => DB::table('master_players')->where('data_version', $version)->whereNotNull('nationality')
                    ->groupBy('nationality')->orderByRaw('count(*) desc')->limit(80)->pluck('nationality')
                    ->map(fn ($n) => Nation::name($n))->unique()->sort()->values(),
                'positions' => DB::table('master_players')->where('data_version', $version)->distinct()->orderBy('position')->pluck('position'),
            ],
            'requests' => $requests->map(fn ($r) => [
                'id' => $r->id, 'status' => $r->status, 'cost' => (int) $r->cost, 'criteria' => json_decode($r->criteria, true),
                'finishes_at' => Carbon::parse($r->finishes_at, 'UTC')->toIso8601ZuluString(),
                'players' => $this->players(json_decode($r->result_player_ids ?? '[]', true), $club->id),
            ]),
        ]);
    }

    public function ask(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        Market::assertOpen($league->id);
        $data = $request->validate([
            'line' => ['nullable', Rule::in(Scout::LINES)],
            'position' => 'nullable|string|max:4',
            'min_overall' => 'required|integer|min:40|max:99',
            'max_overall' => 'nullable|integer|min:40|max:99|gte:min_overall',
            'max_age' => 'nullable|integer|min:16|max:45',
            'nationality' => 'nullable|string|max:60',
            'league' => 'nullable|string|max:60',
            'max_value' => 'nullable|integer|min:1',
            'idempotency_key' => 'required|string|max:64',
        ]);
        $criteria = array_filter(array_diff_key($data, ['idempotency_key' => 1]), fn ($v) => $v !== null && $v !== '');
        Scout::ask($club->id, $criteria, "scout:{$club->id}:{$data['idempotency_key']}");

        return $this->show($request, $league);
    }

    public function finish(Request $request, League $league): JsonResponse
    {
        Finish::scout($this->club($request, $league)->id);

        return $this->show($request, $league);
    }

    /** A report's players as this club sees them: still to buy (with the pool's price), bought, or gone. */
    private function players(array $ids, int $clubId): array
    {
        if (! $ids) {
            return [];
        }

        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', $ids)
            ->get(['players.*', 'master_players.name', 'master_players.position', 'master_players.line', 'master_players.age', 'master_players.nationality', 'master_players.potential'])
            ->map(fn ($p) => ['id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => (int) $p->age,
                'nationality' => Nation::name($p->nationality), 'overall' => (int) $p->overall, 'potential' => (int) $p->potential, 'value' => (int) $p->value,
                'price' => Market::price($p, $clubId),
                'state' => $p->club_id === $clubId ? 'mine' : ($p->club_id === null && $p->scouted_by === $clubId ? 'available' : 'gone')])->all();
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
