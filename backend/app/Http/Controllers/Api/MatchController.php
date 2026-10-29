<?php

namespace App\Http\Controllers\Api;

use App\Data\ClubLogo;
use App\Engine\MatchSetup;
use App\Http\Controllers\Controller;
use App\League\LiveDegrade;
use App\League\MatchOrders;
use App\League\MatchReplay;
use App\League\MatchRunner;
use App\League\MatchSocial;
use App\League\Members;
use App\League\MissedMatches;
use App\League\TeamSheet;
use App\Models\Club;
use App\Simulator\CoachWindows;
use App\Simulator\Simulator;
use App\Support\Activity;
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
                'halftime_seconds' => (int) $state['cfg']['match']['halftime_seconds'],
                'windows' => $state['cfg']['match']['windows'] ?? [], 'window_seconds' => (int) ($state['cfg']['match']['window_seconds'] ?? 0)],
            'clubs' => ['home' => ClubLogo::with($state['teams']['home']['club']), 'away' => ClubLogo::with($state['teams']['away']['club'])],
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
        [$m, $f, $you] = $this->load($request, $match);
        if ($you && $m->status === 'live') {
            MatchOrders::watching($m->id, $you);
        }
        // A match followed live counts once for the activity indicators [PLAN 2.22, Sprint 37].
        if ($m->status === 'live' && Cache::add("watched:{$request->user()->id}:{$m->id}", 1, 3600)) {
            Activity::record($request->user()->id, 'matches_watched');
        }
        $since = max(0, (int) $request->query('since', 0));
        $live = Cache::get("league-match:{$m->id}");
        $ticks = array_values(array_filter($live['recent'] ?? [], fn ($t) => $t['tick'] > $since));
        $now = GameClock::nowMs();
        // Minutes made ahead of their start stay unknown until they start (their score too).
        $shown = array_values(array_filter($ticks, fn ($t) => ($t['at'] ?? 0) <= $now + (int) config('game.match.live_lead_ms')));

        $tick = $shown ? end($shown)['tick'] : $since;
        // Back after a gap (a lost connection, a locked phone, a hidden tab, joining late): one path for all
        // [E8.5]. The screen jumps to now with a summary of everything missed (the goals and the red cards), the
        // events of the latest missed minutes, and the latest minutes whole. At most missed_max_minutes of events
        // per request [E8.6]: the summary covers the rest, so a long gap never makes a big reply.
        $gap = $shown && $shown[0]['tick'] > $since + 1;
        $missed = $gap && LiveDegrade::summary() ? $this->missed($m, $live, $since, $shown[0]['tick'], $you) : [];
        $summary = $gap && LiveDegrade::summary() ? self::summary($missed, $since, $shown[0]['tick']) : null;
        $missed = array_slice($missed, -(int) config('game.live.missed_max_minutes'));

        return response()->json([
            'started' => true,
            'finished' => $m->status === 'finished',
            'tick' => $tick,
            'server_now' => $now,
            'next_at' => $m->status === 'live' ? (int) $m->next_at : null,
            'gap' => $gap,
            'missed' => $missed,
            'summary' => $summary,
            'ticks' => array_map(fn ($t) => LiveDegrade::voice() ? Simulator::redact($t, $you) : ['voice' => null] + Simulator::redact($t, $you), $shown),
            'readings' => $this->readings($m, $f, $you, $tick),
            // [UP17] The break under way: its end, the coaches ready, and whose injured player waits.
            'pause' => $m->status === 'live' ? MatchRunner::pauseOf($m->id) : null,
            // [E8.7] Under load, how long the screens wait between polls (null: their own pace).
            'poll_ms' => LiveDegrade::pollMs(),
        ] + MatchSocial::recent($m->id));
    }

    /** A reaction on every viewer's screen [X24]: an emoji, or a boo or a cheer for one side. Any member who watches. */
    public function react(Request $request, int $match): JsonResponse
    {
        [$m, , $you] = $this->load($request, $match);
        MissedMatches::seen($request->user()->id, [$m->id]);
        $data = $request->validate([
            'key' => ['required', Rule::in([...config('game.match.reactions'), ...MatchSocial::CHEERS])],
            'target' => ['required_if:key,boo,cheer', 'nullable', Rule::in(['home', 'away'])],
        ]);
        abort_unless($m->status === 'live', 409, 'المباراة ليست مباشرة الآن.');

        return response()->json(MatchSocial::react($m->id, $request->user()->id, $request->user()->name, $you, $data['key'], $data['target'] ?? null), 201);
    }

    /** The side chat between the league's coaches who watch [X24]. */
    public function chat(Request $request, int $match): JsonResponse
    {
        [$m, , $you] = $this->load($request, $match);
        $data = $request->validate(['body' => ['required', 'string', 'max:'.config('game.match.chat_max')]]);
        abort_unless($m->status === 'live', 409, 'المباراة ليست مباشرة الآن.');
        $body = trim(preg_replace('/\s+/u', ' ', $data['body']));
        abort_if($body === '', 422, 'اكتب رسالة.');

        return response()->json(MatchSocial::say($m->id, $request->user()->id, $request->user()->name, $you, $body), 201);
    }

    /** The events of the minutes after $since and before $until: the kept ones, then those still in the cache. */
    private function missed(object $m, ?array $live, int $since, int $until, ?string $you): array
    {
        $events = [...array_filter(MatchReplay::events($m->id), fn ($e) => $e['tick'] > $since && $e['tick'] < $until),
            ...array_filter($live['events'] ?? [], fn ($e) => $e['tick'] > $since && $e['tick'] < $until)];
        $byTick = [];
        foreach ($events as $e) {
            $byTick[$e['tick']] ??= ['tick' => $e['tick'], 'minute' => $e['minute'], 'events' => []];
            $byTick[$e['tick']]['events'][] = array_diff_key($e, ['tick' => 1, 'minute' => 1]);
        }
        ksort($byTick);

        return array_map(fn ($t) => Simulator::redact($t, $you), array_values($byTick));
    }

    /**
     * What a screen missed in a gap [E8.5]: how many minutes, and the goals and red cards in them, in order.
     * Built from the redacted minutes, so it holds nothing hidden.
     */
    public static function summary(array $missed, int $since, int $until): array
    {
        $goals = $reds = [];
        foreach ($missed as $t) {
            foreach ($t['events'] as $e) {
                if ($e['type'] === 'goal') {
                    $goals[] = ['minute' => $t['minute'], 'team' => $e['team'], 'scorer' => $e['scorer'] ?? null];
                } elseif ($e['type'] === 'card' && ($e['color'] ?? null) === 'red') {
                    $reds[] = ['minute' => $t['minute'], 'team' => $e['team'], 'player' => $e['player'] ?? null];
                }
            }
        }

        return ['from_tick' => $since + 1, 'to_tick' => $until - 1, 'minutes' => max(0, $until - 1 - $since), 'goals' => $goals, 'reds' => $reds];
    }

    /** The assistant's readings to this coach so far (other members get none). */
    private function readings(object $m, object $f, ?string $you, int $tick): array
    {
        if (! $you) {
            return [];
        }

        return DB::table('match_readings')->where('match_id', $m->id)->where('club_id', $you === 'home' ? $f->home_id : $f->away_id)
            ->where('tick', '<=', $tick)->orderByDesc('tick')->limit(20)->get(['id', 'tick', 'minute', 'kind', 'text'])
            ->reverse()->values()->all();
    }

    /** "Why you won or lost" [ENGINE 8.1]: for the coaches of the two sides, each his own. */
    public function report(Request $request, int $match): JsonResponse
    {
        [$m, $f, $you] = $this->load($request, $match);
        abort_unless($you, 403, 'التقرير لمدربي الفريقين فقط.');
        // [Sprint 20 B3] Read: the after-round window no longer offers it.
        MissedMatches::seen($request->user()->id, [$m->id]);
        $row = DB::table('match_reports')->where('match_id', $m->id)->where('club_id', $you === 'home' ? $f->home_id : $f->away_id)->first();
        abort_unless($m->status === 'finished' && $row, 409, 'المباراة لم تنتهِ بعد.');

        return response()->json(['side' => $you] + json_decode($row->report, true));
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
        Activity::record($request->user()->id, 'orders');
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
        $state = Cache::get("league-match:{$m->id}")['state'] ?? json_decode($m->state, true);
        // [UP17] The emergency stop for an injured player: his coach alone, and only to bring someone on for him.
        $injured = CoachWindows::emergencyFor($state, $you);
        if ($injured !== null) {
            abort_unless($action['type'] === 'sub' && (int) ($action['out'] ?? 0) === $injured, 409, 'في التوقف الطارئ تبدّل اللاعب المصاب فقط.');
        } else {
            // [X42] Only in a window: before kick-off, at half-time, or the break after minutes 15, 30, 60 and 75.
            abort_unless(CoachWindows::open($state), 409, 'التغيير في فترات التوقف فقط: قبل البداية، وفي الدقائق 15 و30 و45 و60 و75.');
        }
        $tick = max((int) $m->tick, (int) ($state['tick'] ?? 0)) + 1;
        $new = MatchOrders::give($m->id, $you, $request->user()->id, $data['idempotency_key'], $action, $tick);
        $row = DB::table('match_actions')->where('match_id', $m->id)->where('idempotency_key', $data['idempotency_key'])->first();

        return response()->json(['target_tick' => $row->target_tick, 'duplicate' => ! $new], $new ? 202 : 200);
    }

    /** [UP17] «أنا مستعد»: the coach is done with this break; once both coaches are, play goes on at once. */
    public function ready(Request $request, int $match): JsonResponse
    {
        [$m, , $you] = $this->load($request, $match);
        abort_unless($you, 403, 'لا تدير أياً من الفريقين في هذه المباراة.');
        abort_unless($m->mode === 'live' && $m->status === 'live', 409, 'انتهت المباراة.');
        MatchOrders::watching($m->id, $you);

        return response()->json(MatchRunner::ready($m->id, $you));
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
