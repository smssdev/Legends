<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\Spy;
use App\Models\Club;
use App\Models\League;
use App\Training\SecretTraining;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/** Spying on the next opponent [docs/features/spy.md, Sprint 30]: whether a spy can go, and his report. */
class SpyController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $f = SecretTraining::nextFixture($club->id);
        $saved = $f ? DB::table('spy_reports')->where('club_id', $club->id)->where('fixture_id', $f->id)->value('report') : null;

        return response()->json([
            'cost' => Spy::cost($league->id),
            'fixture' => $f ? [
                'id' => $f->id, 'status' => $f->status,
                'opponent' => DB::table('clubs')->where('id', $f->home_id === $club->id ? $f->away_id : $f->home_id)->value('name'),
                'lock_at' => Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(config('game.match.lock_minutes_before'))->toIso8601ZuluString(),
            ] : null,
            'report' => $saved ? json_decode($saved, true) : null,
        ]);
    }

    public function send(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $f = SecretTraining::nextFixture($club->id);
        abort_unless($f, 409, 'لا مباراة قادمة لفريقك.');
        Spy::send($club->id, $f);

        return $this->show($request, $league);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
