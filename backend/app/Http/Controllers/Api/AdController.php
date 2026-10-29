<?php

namespace App\Http\Controllers\Api;

use App\Ads\AdReward;
use App\Ads\HouseAds;
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
    /** [Sprint 20 S4] A watch of one of the game's own ads: the ad and the token that claims the reward at its end. */
    public function start(Request $request): JsonResponse
    {
        abort_unless(config('game.ads.enabled') && config('game.ads.driver') === 'house', 503, 'الإعلانات غير مفعّلة بعد.');

        return response()->json(HouseAds::start($request->user()->id, (string) ($request->user()->locale ?? app()->getLocale())), 201);
    }

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
