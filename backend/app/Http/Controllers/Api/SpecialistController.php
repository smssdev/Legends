<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\League;
use App\Staff\Specialists;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** Specialists [docs/features/specialists.md, Sprint 31]: the four, each with its price and the contract working now. */
class SpecialistController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);

        return response()->json([
            'balance' => (int) DB::table('clubs')->where('id', $club->id)->value('balance'),
            'now' => GameClock::now()->toIso8601ZuluString(),
            'days' => intdiv(Specialists::seconds($league->id), 86400) ?: 1,
            'specialists' => array_map(function ($type) use ($club, $league) {
                $c = Specialists::current($club->id, $type);

                return ['type' => $type, 'cost' => Specialists::cost($league->id, $type),
                    'ends_at' => $c ? Carbon::parse($c->ends_at, 'UTC')->toIso8601ZuluString() : null];
            }, Specialists::TYPES),
        ]);
    }

    public function hire(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['type' => ['required', Rule::in(Specialists::TYPES)], 'idempotency_key' => 'required|string|max:64']);
        Specialists::hire($club->id, $data['type'], "specialist:{$club->id}:{$data['idempotency_key']}");

        return $this->show($request, $league);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
