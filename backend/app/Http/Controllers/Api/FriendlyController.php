<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\Friendlies;
use App\Models\Club;
use App\Models\League;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** [Sprint 20 B4, Sprint 24 B2] The friendlies: who to play, what one costs, and a match now with no effect. */
class FriendlyController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        return response()->json(Friendlies::view($this->club($request, $league)));
    }

    public function play(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['opponent_id' => ['required', 'integer'], 'idempotency_key' => ['required', 'string', 'max:64']]);
        [$played, $new] = Friendlies::play($club, (int) $data['opponent_id'], $request->user()->id, $data['idempotency_key']);

        return response()->json(['friendly' => $played] + Friendlies::view($club->fresh()), $new ? 201 : 200);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
