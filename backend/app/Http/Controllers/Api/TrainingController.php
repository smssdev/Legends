<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Messages\MessageText;
use App\Models\Club;
use App\Models\League;
use App\Staff\Specialists;
use App\Support\GameClock;
use App\Training\Gain;
use App\Training\Training;
use App\Wallet\Finish;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/** Training [PLAN 2.8, Sprint 27]: the four slots with their bars and next session, and who can fill them. */
class TrainingController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        // Sessions due while nobody looked run first, so the screen shows the bars as they are.
        foreach (DB::table('training_slots')->where('club_id', $club->id)->pluck('id') as $id) {
            Training::catchUp((int) $id);
        }
        $gain = Gain::fromConfig();
        $slots = DB::table('training_slots')->where('club_id', $club->id)->get()->keyBy('line');
        $players = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $club->id)
            ->orderByRaw('players.overall + players.training_bonus desc')->orderBy('players.id')
            ->get(['players.id', 'players.overall', 'players.training_bonus', 'players.training_progress', 'players.injured_matches',
                'master_players.name', 'master_players.position', 'master_players.line', 'master_players.age', 'master_players.potential'])
            ->map(fn ($p) => [
                'id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => (int) $p->age,
                'overall' => $p->overall + $p->training_bonus, 'training_bonus' => (int) $p->training_bonus, 'potential' => (int) $p->potential,
                'progress' => intdiv($p->training_progress * 100, (int) config('game.training.progress_scale')),
                'sessions' => $gain->sessions($p->overall + $p->training_bonus, (int) $p->potential),
                'injured' => $p->injured_matches > 0,
                'maxed' => $p->overall + $p->training_bonus >= $gain->ceiling(),
                'over_potential' => $p->overall + $p->training_bonus >= $p->potential,
            ])->keyBy('id');

        return response()->json([
            'cost' => Training::cost($league->id),
            'balance' => (int) DB::table('clubs')->where('id', $club->id)->value('balance'),
            'interval_minutes' => intdiv(Training::interval($league->id), 60),
            'now' => GameClock::now()->toIso8601ZuluString(),
            'slots' => array_map(function ($line) use ($slots, $players, $club) {
                $s = $slots[$line] ?? null;
                $coach = Specialists::LINE_COACH[$line];

                return ['line' => $line, 'player' => $s ? $players[$s->player_id] ?? null : null, 'sessions_done' => $s ? (int) $s->sessions : 0,
                    'next_at' => $s ? Carbon::parse($s->next_at, 'UTC')->toIso8601ZuluString() : null,
                    // [Sprint 21 E6] The line trains only with its coach.
                    'coach' => ['type' => $coach, 'name' => __(MessageText::STAFF[$coach]), 'hired' => Specialists::has($club->id, $coach)]];
            }, Training::LINES),
            'players' => $players->values(),
        ]);
    }

    public function add(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['player_id' => 'required|integer']);
        Training::add($club->id, $data['player_id']);

        return $this->show($request, $league);
    }

    public function finish(Request $request, League $league, string $line): JsonResponse
    {
        Finish::training($this->club($request, $league)->id, $line);

        return $this->show($request, $league);
    }

    public function remove(Request $request, League $league, string $line): JsonResponse
    {
        $club = $this->club($request, $league);
        Training::remove($club->id, $line);

        return $this->show($request, $league);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
