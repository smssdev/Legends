<?php

namespace App\Http\Controllers\Api;

use App\Engine\MatchSetup;
use App\Http\Controllers\Controller;
use App\League\Members;
use App\Simulator\Simulator;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * A league match for the viewer [Sprint 18 W1]: the same shape as the simulator's live match, so the same
 * screen plays it. For the league's members only. Each side's tactics reach only its own coach.
 */
class MatchController extends Controller
{
    public function show(Request $request, int $match): JsonResponse
    {
        [$m, $f, $you] = $this->load($request, $match);
        $state = json_decode($m->initial_state, true);
        $view = [
            'id' => $m->id, 'fixture_id' => $f->id, 'league_id' => $f->league_id, 'competition' => $f->competition, 'round' => $f->round,
            'mode' => $m->mode, 'status' => $m->status, 'you' => $you, 'started' => true,
            'finished' => $m->status === 'finished', 'score' => ['home' => $m->home_goals, 'away' => $m->away_goals], 'tick' => $m->tick,
            'timing' => ['tick_ms' => (int) $state['cfg']['match']['tick_ms'], 'extra_time_tick_ms' => (int) $state['cfg']['match']['extra_time_tick_ms'],
                'halftime_seconds' => (int) $state['cfg']['match']['halftime_seconds']],
            'clubs' => ['home' => $state['teams']['home']['club'], 'away' => $state['teams']['away']['club']],
            'coaches' => DB::table('clubs')->leftJoin('users', 'users.id', '=', 'clubs.user_id')->whereIn('clubs.id', [$f->home_id, $f->away_id])
                ->pluck('users.name', 'clubs.id')->mapWithKeys(fn ($n, $id) => [$id === $f->home_id ? 'home' : 'away' => $n])->filter(),
            'teams' => Simulator::redact(['teams' => Simulator::teams($state)], $you)['teams'],
            'slots' => ['home' => MatchSetup::slots($state['teams']['home']), 'away' => MatchSetup::slots($state['teams']['away'])],
        ];

        return response()->json($view);
    }

    /** The minutes made after $since, with their frames, as the simulator's live sync gives them. */
    public function live(Request $request, int $match): JsonResponse
    {
        [$m, , $you] = $this->load($request, $match);
        $since = (int) $request->query('since', 0);
        $live = Cache::get("league-match:{$m->id}");
        $ticks = array_values(array_filter($live['recent'] ?? [], fn ($t) => $t['tick'] > $since));
        $now = GameClock::nowMs();
        // Minutes made ahead of their start stay unknown until they start (their score too).
        $shown = array_values(array_filter($ticks, fn ($t) => ($t['at'] ?? 0) <= $now + (int) config('game.match.live_lead_ms')));

        return response()->json([
            'started' => true,
            'finished' => $m->status === 'finished',
            'tick' => $shown ? end($shown)['tick'] : $since,
            'server_now' => $now,
            'next_at' => $m->status === 'live' ? (int) $m->next_at : null,
            'gap' => $shown && $shown[0]['tick'] > $since + 1,
            'ticks' => array_map(fn ($t) => Simulator::redact($t, $you), $shown),
            'reactions' => [],
        ]);
    }

    /** The match, its fixture, and which side the asker coaches (null for the other members). 404 for outsiders. */
    private function load(Request $request, int $id): array
    {
        $m = DB::table('matches')->where('id', $id)->first();
        abort_unless($m, 404);
        $f = DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->where('fixtures.id', $m->fixture_id)
            ->select('fixtures.*', 'seasons.league_id')->first();
        abort_unless(Members::isMember($request->user()->id, $f->league_id), 404);
        $mine = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->where('user_id', $request->user()->id)->value('id');
        $you = $mine ? ($mine === $f->home_id ? 'home' : 'away') : null;

        return [$m, $f, $you];
    }
}
