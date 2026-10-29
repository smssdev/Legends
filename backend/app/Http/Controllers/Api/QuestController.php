<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\WeeklyQuests;
use App\Models\Club;
use App\Models\League;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** [Sprint 20 B5] The weekly quests: this week's progress, and a finished quest's reward. */
class QuestController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        return response()->json(WeeklyQuests::view($this->club($request, $league), $request->user()->id));
    }

    public function claim(Request $request, League $league): JsonResponse
    {
        $quest = $request->validate(['quest' => ['required', 'string', Rule::in(WeeklyQuests::QUESTS)]])['quest'];

        return response()->json(WeeklyQuests::claim($this->club($request, $league), $request->user()->id, $quest));
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
