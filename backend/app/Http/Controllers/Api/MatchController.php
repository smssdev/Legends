<?php

namespace App\Http\Controllers\Api;

use App\Engine\MatchSetup;
use App\Http\Controllers\Controller;
use App\League\MatchOrders;
use App\League\MatchReplay;
use App\League\Members;
use App\League\TeamSheet;
use App\Models\Club;
use App\Simulator\Simulator;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * A league match for the viewer [Sprint 18 W1]: the same shape as the simulator's live match, so the same
 * screen plays it. For the league's members only. Each side's tactics reach only its own coach, and only
 * he gives its orders while it is played [Sprint 19]; while his screen is away his assistant does.
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
            // The simulator's shape: the side you manage is "me" (the viewer shows its coach panel).
            'control' => ['home' => $you === 'home' ? 'me' : 'cpu', 'away' => $you === 'away' ? 'me' : 'cpu'],
            // What the coach can switch to while it is played: the 24 and his own.
            'formations' => $you ? array_keys(TeamSheet::formations(Club::findOrFail($you === 'home' ? $f->home_id : $f->away_id))) : [],
        ];

        return response()->json($view);
    }

    /** The minutes made after $since, with their frames, as the simulator's live sync gives them. */
    public function live(Request $request, int $match): JsonResponse
    {
        [$m, , $you] = $this->load($request, $match);
        if ($you && $m->status === 'live') {
            MatchOrders::watching($m->id, $you);
        }
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

    /**
     * An order from a side's coach [PLAN 2.12]: a substitution, tactics, or a formation. It goes into the next
     * minute not yet made, checked there by the engine's own rules (a rejected one comes back on his screen).
     */
    public function order(Request $request, int $match): JsonResponse
    {
        [$m, $f, $you] = $this->load($request, $match);
        abort_unless($you, 403, 'لا تدير أياً من الفريقين في هذه المباراة.');
        // The 24 formations and the coach's own, each with its slots (the engine takes them with the order).
        $formations = TeamSheet::formations(Club::findOrFail($you === 'home' ? $f->home_id : $f->away_id));
        abort_unless($m->mode === 'live' && $m->status === 'live', 409, 'انتهت المباراة.');
        $data = $request->validate([
            'type' => 'required|in:sub,tactics,formation',
            'out' => 'required_if:type,sub|integer',
            'in' => 'required_if:type,sub|integer',
            'tactics' => 'required_if:type,tactics|array|max:10',
            'formation' => ['required_if:type,formation', 'nullable', 'string', Rule::in(array_keys($formations))],
            'idempotency_key' => 'required|string|max:64',
        ]);
        $action = array_filter(['type' => $data['type'], 'out' => $data['out'] ?? null, 'in' => $data['in'] ?? null,
            'tactics' => $data['tactics'] ?? null, 'formation' => $data['formation'] ?? null,
            'slots' => isset($data['formation']) ? $formations[$data['formation']] : null], fn ($v) => $v !== null);
        MatchOrders::watching($m->id, $you);
        $tick = max((int) $m->tick, (int) (Cache::get("league-match:{$m->id}")['state']['tick'] ?? 0)) + 1;
        $new = MatchOrders::give($m->id, $you, $request->user()->id, $data['idempotency_key'], $action, $tick);
        $row = DB::table('match_actions')->where('match_id', $m->id)->where('idempotency_key', $data['idempotency_key'])->first();

        return response()->json(['target_tick' => $row->target_tick, 'duplicate' => ! $new], $new ? 202 : 200);
    }

    /**
     * A played match again [Sprint 19 B3]: every minute with its frames from the seed and the orders, while
     * the engine is the same version; an older one gives its stored events only.
     */
    public function replay(Request $request, int $match): JsonResponse
    {
        [$m, , $you] = $this->load($request, $match);
        abort_unless($m->status === 'finished', 409, 'المباراة لم تنتهِ بعد.');
        if (! MatchReplay::replayable($m)) {
            return response()->json(['replayable' => false, 'ticks' => null, 'events' => array_map(fn ($e) => Simulator::redact(['events' => [$e]], $you)['events'][0], MatchReplay::events($m->id))]);
        }

        return response()->json(['replayable' => true, 'ticks' => array_map(fn ($t) => Simulator::redact($t, $you), MatchReplay::ticks($m)), 'events' => null]);
    }

    /** My matches being played now, in every league: the viewer switches between them. */
    public function mine(Request $request): JsonResponse
    {
        $clubs = DB::table('clubs')->where('user_id', $request->user()->id)->pluck('id');
        $rows = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
            ->where('matches.status', 'live')->where('matches.mode', 'live')
            ->where(fn ($q) => $q->whereIn('fixtures.home_id', $clubs)->orWhereIn('fixtures.away_id', $clubs))
            ->join('clubs as h', 'h.id', '=', 'fixtures.home_id')->join('clubs as a', 'a.id', '=', 'fixtures.away_id')
            ->select('matches.id', 'matches.tick', 'h.code as home', 'a.code as away', 'fixtures.competition')->orderBy('matches.id')->get();

        return response()->json(['matches' => $rows->map(fn ($r) => ['id' => $r->id, 'home' => $r->home, 'away' => $r->away, 'competition' => $r->competition])->values()]);
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
