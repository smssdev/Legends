<?php

namespace App\Http\Controllers\Api;

use App\Economy\Economy;
use App\Economy\Money;
use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\League;
use App\Stadium\Stadium;
use App\Support\GameClock;
use App\Wallet\Finish;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** The stadium [PLAN 2.9, Sprint 29]: the three sections with their stages and effects, and the part being built. */
class StadiumController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        Stadium::due();
        $cfg = config('game.stadium');
        $stages = Stadium::stages($club->id);
        $parts = DB::table('stadium_sections')->where('club_id', $club->id)->pluck('parts', 'section');
        $building = Stadium::building($club->id);
        $money = Money::fromConfig();
        [$min, $max] = Economy::strengthRange($league->id);
        $scale = Economy::scale($league->id);
        $rounds = (int) $league->season->rounds;
        $attendance = $money->attendance((int) $club->strength_snapshot, $min, $max);
        $per = (int) $cfg['parts_per_stage'];
        // What each stage gives, from stage 0 to 3.
        $effects = [
            'seats' => array_map(fn ($c) => $money->tickets($scale, $rounds, $attendance, $c), $cfg['capacity_by_stage']),
            'pitch' => array_map(fn ($bp) => (int) $bp, config('game.match.home_pitch_bp')),
            'training' => array_map(fn ($r) => (int) $r[1], $cfg['training_speed_bp']),
        ];

        return response()->json([
            'balance' => (int) DB::table('clubs')->where('id', $club->id)->value('balance'),
            'now' => GameClock::now()->toIso8601ZuluString(),
            'part_minutes' => intdiv(Stadium::partSeconds($league->id), 60),
            'parts_total' => count(Stadium::SECTIONS) * $cfg['stages'] * $per,
            'facts' => [
                'capacity' => Stadium::capacity($club->id),
                'home_bp' => (int) config('game.match.home_base_bp') + $effects['pitch'][$stages['pitch']],
                'tickets_per_match' => $effects['seats'][$stages['seats']],
                'parts_done' => array_sum(array_map(fn ($s) => $stages[$s] * $per + (int) ($parts[$s] ?? 0), Stadium::SECTIONS)),
            ],
            'sections' => array_map(function ($s) use ($club, $league, $stages, $parts, $per, $effects) {
                $next = Stadium::nextPart($club->id, $s);

                return [
                    'section' => $s, 'stage' => $stages[$s], 'parts' => (int) ($parts[$s] ?? 0),
                    'done' => $stages[$s] * $per + (int) ($parts[$s] ?? 0),
                    'effects' => $effects[$s],
                    'next' => $next ? ['stage' => $next[0], 'part' => $next[1], 'cost' => Stadium::partCost($league->id, $next[0])] : null,
                ];
            }, Stadium::SECTIONS),
            'building' => $building ? [
                'section' => $building->section, 'stage' => (int) $building->stage, 'part' => (int) $building->part,
                'ends_at' => Carbon::parse($building->ends_at, 'UTC')->toIso8601ZuluString(),
            ] : null,
        ]);
    }

    public function start(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['section' => ['required', Rule::in(Stadium::SECTIONS)], 'idempotency_key' => 'required|string|max:64']);
        Stadium::start($club->id, $data['section'], "stadium:{$club->id}:{$data['idempotency_key']}");

        return $this->show($request, $league);
    }

    public function finish(Request $request, League $league): JsonResponse
    {
        Finish::stadium($this->club($request, $league)->id);

        return $this->show($request, $league);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
