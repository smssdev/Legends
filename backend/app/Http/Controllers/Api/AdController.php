<?php

namespace App\Http\Controllers\Api;

use App\Ads\AdReward;
use App\Ads\RewardVerifier;
use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\League;
use App\Training\Training;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** [Sprint 21 E9] A rewarded video the provider verified cuts the coach's training or stadium time. */
class AdController extends Controller
{
    public function reward(Request $request, League $league, RewardVerifier $verifier): JsonResponse
    {
        $data = $request->validate([
            'item' => ['required', 'string', Rule::in(AdReward::ITEMS)],
            'line' => ['required_if:item,training', 'nullable', 'string', Rule::in(Training::LINES)],
            'token' => ['required', 'string', 'max:4096'],
        ]);
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return response()->json(AdReward::apply($verifier, $request->user()->id, $club->id, $data['item'], $data['line'] ?? null, $data['token']));
    }
}
