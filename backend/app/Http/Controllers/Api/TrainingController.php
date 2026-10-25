<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\League;
use App\Support\GameClock;
use App\Training\Camp;
use App\Training\Gain;
use App\Training\SecretTraining;
use App\Training\Training;
use App\Wallet\Finish;
use App\Wallet\Price;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

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
        Camp::due();
        $away = Camp::awayIds($club->id);
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
                'in_camp' => in_array($p->id, $away, true),
            ])->keyBy('id');

        return response()->json([
            'cost' => Training::cost($league->id),
            'balance' => (int) DB::table('clubs')->where('id', $club->id)->value('balance'),
            'interval_minutes' => intdiv(Training::interval($league->id), 60),
            'now' => GameClock::now()->toIso8601ZuluString(),
            'slots' => array_map(function ($line) use ($slots, $players) {
                $s = $slots[$line] ?? null;

                return ['line' => $line, 'player' => $s ? $players[$s->player_id] ?? null : null, 'sessions_done' => $s ? (int) $s->sessions : 0,
                    'next_at' => $s ? Carbon::parse($s->next_at, 'UTC')->toIso8601ZuluString() : null];
            }, Training::LINES),
            'players' => $players->values(),
            'camp' => $this->camp($club, $league),
            'secret' => $this->secret($club, $league),
        ]);
    }

    public function sendToCamp(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $cfg = config('game.camp');
        $data = $request->validate([
            'player_ids' => 'required|array|min:1|max:'.$cfg['max_players'],
            'player_ids.*' => 'integer',
            'level' => ['required', Rule::in(Camp::LEVELS)],
            'days' => "required|integer|min:{$cfg['days'][0]}|max:{$cfg['days'][1]}",
            'idempotency_key' => 'required|string|max:64',
        ]);
        Camp::send($club->id, $data['player_ids'], $data['level'], $data['days'], "camp:{$club->id}:{$data['idempotency_key']}");

        return $this->show($request, $league);
    }

    public function secretSession(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['line' => ['required', Rule::in(SecretTraining::LINES)]]);
        $fixture = SecretTraining::nextFixture($club->id);
        abort_unless($fixture, 409, 'لا مباراة قادمة لفريقك.');
        SecretTraining::order($club->id, $fixture, $data['line']);

        return $this->show($request, $league);
    }

    /** The camp: the levels with a player-day's price, and the one under way (or the last one) with its players. */
    private function camp(Club $club, League $league): array
    {
        $cfg = config('game.camp');
        $last = DB::table('training_camps')->where('club_id', $club->id)->orderByDesc('id')->first();
        $gains = $last ? json_decode($last->gains, true) ?: [] : [];

        return [
            'max_players' => $cfg['max_players'], 'days' => $cfg['days'], 'min_left' => $cfg['min_left'],
            'levels' => array_map(fn ($l) => ['level' => $l, 'gain_bp' => $cfg['levels'][$l]['gain_bp'], 'day_price' => Camp::price($league->id, $l, 1, 1)], Camp::LEVELS),
            'current' => $last ? [
                'id' => $last->id, 'level' => $last->level, 'status' => $last->status, 'cost' => (int) $last->cost,
                'sessions' => (int) $last->sessions, 'sessions_done' => (int) $last->sessions_done,
                'ends_at' => Carbon::parse($last->ends_at, 'UTC')->toIso8601ZuluString(),
                'players' => array_map(fn ($id) => ['id' => $id, 'gain' => (int) ($gains[$id] ?? 0)], json_decode($last->player_ids, true)),
            ] : null,
        ];
    }

    /** Secret training for the next match: whether it can still be ordered, and what was ordered. */
    private function secret(Club $club, League $league): array
    {
        $f = SecretTraining::nextFixture($club->id);
        $season = $league->season;

        return [
            ...(fn ($q) => ['cost' => $q['amount'], 'currency' => $q['currency']])(Price::quote($league->id, 'secret_training', SecretTraining::cost($league->id))),
            'boost' => (int) config('game.secret_training.boost'),
            'per_season' => (int) config('game.secret_training.per_season'),
            'used' => $season ? SecretTraining::usedThisSeason($club->id, $season->id) : 0,
            'fixture' => $f ? [
                'id' => $f->id, 'competition' => $f->competition, 'round' => (int) $f->round, 'status' => $f->status,
                'opponent' => DB::table('clubs')->where('id', $f->home_id === $club->id ? $f->away_id : $f->home_id)->value('name'),
                'lock_at' => Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(config('game.match.lock_minutes_before'))->toIso8601ZuluString(),
                'line' => array_key_first(SecretTraining::boosts($club->id, $f->id)),
            ] : null,
        ];
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
