<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Market\Auctions;
use App\Market\BotNegotiation;
use App\Market\ReleaseClause;
use App\Models\Club;
use App\Models\League;
use App\Store\Chests;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * [Sprint 50 M18, M19, M21] The market's new deals: the league's auctions and their bids, a coach's player taken at
 * his release clause, the talk with a computer club over one of its players, and the store's chests.
 */
class DealsController extends Controller
{
    public function auctions(Request $request, League $league): JsonResponse
    {
        return response()->json(['auctions' => Auctions::of($league->id, $this->club($request, $league)->id),
            'minutes' => config('game.auctions.minutes')]);
    }

    public function bid(Request $request, League $league, int $player): JsonResponse
    {
        $data = $request->validate(['amount' => 'required|integer|min:1', 'idempotency_key' => 'required|string|max:64']);

        return response()->json(['auction' => Auctions::bid($this->club($request, $league)->id, $player, $data['amount'], $data['idempotency_key'])]);
    }

    public function releaseQuote(Request $request, League $league, int $player): JsonResponse
    {
        return response()->json(ReleaseClause::quote($this->club($request, $league)->id, $player));
    }

    public function release(Request $request, League $league, int $player): JsonResponse
    {
        $data = $request->validate(['idempotency_key' => 'required|string|max:64']);

        return response()->json(ReleaseClause::pay($this->club($request, $league)->id, $player, $data['idempotency_key']));
    }

    public function negotiation(Request $request, League $league, int $player): JsonResponse
    {
        return response()->json(BotNegotiation::view($this->club($request, $league)->id, $player));
    }

    public function negotiate(Request $request, League $league, int $player): JsonResponse
    {
        $data = $request->validate(['amount' => 'required|integer|min:1', 'idempotency_key' => 'required|string|max:64']);

        return response()->json(BotNegotiation::offer($this->club($request, $league)->id, $player, $data['amount'], $data['idempotency_key']));
    }

    public function chests(Request $request, League $league): JsonResponse
    {
        $this->club($request, $league);

        return response()->json(['chests' => Chests::catalog()]);
    }

    public function openChest(Request $request, League $league, string $chest): JsonResponse
    {
        $data = $request->validate(['idempotency_key' => 'required|string|max:64']);

        return response()->json(['opened' => Chests::open($this->club($request, $league), $request->user()->id, $chest, $data['idempotency_key'])]);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
