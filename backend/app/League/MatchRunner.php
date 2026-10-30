<?php

namespace App\League;

use App\Characters\Mood;
use App\Events\ClubReading;
use App\Events\MatchMinute;
use App\Simulator\CoachWindows;
use App\Simulator\Commentary;
use App\Simulator\MatchChoreographer;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use App\Simulator\Simulator;
use App\Simulator\Voice;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Plays the league's matches [PLAN 2.12]. One step looks at the clock and:
 *  1. locks any side still open (MatchPrep) and starts each locked fixture whose time has come: live
 *     (minute by minute, broadcast) when a coach is in it and it is at most 10 minutes late; at once
 *     otherwise (bot against bot, shown at its natural end; or long missed, shown as a replay);
 *  2. plays every live minute that is due, on the same timing as the simulator (each minute as long as its
 *     scene), keeping the state in the cache and writing the row at half-time and at the end;
 *  3. publishes the instant matches whose natural end has come.
 * A match that stopped (the runner was killed) resumes from its last saved state: the engine is
 * deterministic, so it ends with the same result it would have had.
 */
class MatchRunner
{
    /** Steps of a match that failed in this process, and the last messages (matches:load-test reads them). */
    public static int $failures = 0;

    public static array $lastErrors = [];

    public static function step(): array
    {
        MatchPrep::run();
        $started = 0;
        foreach (DB::table('fixtures')->where('status', 'locked')->where('scheduled_at', '<=', GameClock::now())->orderBy('scheduled_at')->pluck('id') as $id) {
            $started += self::guarded(fn () => self::start($id) ? 1 : 0);
        }
        $minutes = 0;
        $due = DB::table('matches')->where('status', 'live')->where('next_at', '<=', GameClock::nowMs() + self::lead())->orderBy('next_at')->get(['id', 'next_at']);
        $began = GameClock::stopwatchNs();
        foreach ($due as $m) {
            $minutes += self::guarded(fn () => self::play($m->id));
        }
        // [Sprint 20 S6] How late this step played its oldest due minute, or how long it took, feeds the automatic
        // degradation; a step with nothing due reports 0, so the load falls back when the rush is over.
        if ($due->isNotEmpty() || DB::table('matches')->where('status', 'live')->exists()) {
            LiveDegrade::observe($due->isEmpty() ? 0 : max(GameClock::nowMs() - (int) $due->first()->next_at, intdiv(GameClock::stopwatchNs() - $began, 1_000_000)));
        }
        $published = 0;
        foreach (DB::table('matches')->where('status', 'done')->where('publish_at', '<=', GameClock::now())->pluck('id') as $id) {
            $published += self::guarded(fn () => self::publish($id) ? 1 : 0);
        }

        return [$started, $minutes, $published];
    }

    /**
     * [X45] Whether a match is live, about to be published, or starts soon: then the runner steps every
     * runner_sleep_ms, else it rests runner_idle_ms between steps. Locking a fixture is MatchPrep's, on the minute.
     */
    public static function busy(): bool
    {
        $now = GameClock::now();

        return DB::table('matches')->whereIn('status', ['live', 'done'])->exists()
            || DB::table('fixtures')->whereIn('status', ['scheduled', 'locked'])->where('is_bye', false)
                ->whereBetween('scheduled_at', [$now->copy()->subMinutes((int) config('game.matches.missed_live_minutes')),
                    $now->copy()->addSeconds((int) config('game.matches.runner_busy_ahead_s'))])->exists();
    }

    /**
     * Only one runner plays at a time (two would make the same minute twice): the one that holds this claim,
     * renewed every step. A second one waits; it takes over within seconds if the first one stops.
     */
    public static function claim(string $token): bool
    {
        // [X43] On Supabase two servers share the database (Render runs the old and the new one for a minute on a
        // deploy), but not this cache: the database's own lock, held by the runner's connection until it stops.
        if (DB::getDriverName() === 'pgsql' && ! self::$locked) {
            if (! DB::selectOne('select pg_try_advisory_lock(?) as ok', [self::RUNNER_LOCK])->ok) {
                return false;
            }
            self::$locked = true;
        }
        $ttl = (int) config('game.matches.claim_seconds');
        if (Cache::add('matches-runner', $token, $ttl)) {
            return true;
        }
        if (Cache::get('matches-runner') === $token) {
            Cache::put('matches-runner', $token, $ttl);

            return true;
        }

        return false;
    }

    public static function release(string $token): void
    {
        if (Cache::get('matches-runner') === $token) {
            Cache::forget('matches-runner');
        }
        if (self::$locked) {
            DB::select('select pg_advisory_unlock(?)', [self::RUNNER_LOCK]);
            self::$locked = false;
        }
    }

    /** The key of the runner's lock on PostgreSQL [X43], and whether this process holds it. */
    public const RUNNER_LOCK = 4_204_202;

    private static bool $locked = false;

    /** One match's trouble (a busy database, a broken state) is logged and never holds up the others. */
    private static function guarded(callable $work): int
    {
        try {
            return $work();
        } catch (Throwable $e) {
            report($e);
            self::$failures++;
            self::$lastErrors = array_slice([...self::$lastErrors, $e->getMessage()], -20);

            return 0;
        }
    }

    private static function lead(): int
    {
        return (int) config('game.match.live_lead_ms');
    }

    /** Make the match for a locked fixture: live, or at once. False when it already has one. */
    public static function start(int $fixtureId): bool
    {
        return DB::transaction(function () use ($fixtureId) {
            $now = GameClock::now();
            if (DB::table('fixtures')->where('id', $fixtureId)->where('status', 'locked')->update(['status' => 'live', 'updated_at' => $now]) !== 1) {
                return false;
            }
            $f = DB::table('fixtures')->where('id', $fixtureId)->first();
            $seed = random_int(1, 2_000_000_000);
            $state = LeagueMatch::state($f, $seed);
            $at = Carbon::parse($f->scheduled_at, 'UTC');
            $late = $at->diffInMinutes($now) > config('game.matches.missed_live_minutes');
            $coached = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->whereNotNull('user_id')->exists();
            $live = $coached && ! $late;
            $id = DB::table('matches')->insertGetId([
                'fixture_id' => $f->id, 'seed' => $seed, 'engine_version' => $state['v'], 'config_snapshot' => json_encode($state['cfg']),
                'initial_state' => json_encode($state), 'state' => json_encode($state), 'mode' => $live ? 'live' : 'instant',
                'status' => 'live', 'next_at' => $live ? max($at->getTimestampMs(), GameClock::nowMs()) : null,
                'started_at' => $now, 'created_at' => $now, 'updated_at' => $now,
            ]);
            if (! $live) {
                // Nobody follows an instant match: the assistant manages a coach's side, the computer a bot's.
                $managers = array_map(fn ($c) => $c === 'coach' ? 'assistant' : 'cpu', MatchOrders::control($f));
                self::instant($id, $state, $managers, $at, $late);
            }

            return true;
        });
    }

    /** Bot against bot (or long missed): the whole match now. */
    private static function instant(int $id, array $state, array $managers, Carbon $from, bool $missed): void
    {
        $ball = [525, 340];
        $events = [];
        $orders = [];
        $ms = 0;
        MatchOrders::forget($id);
        while (! $state['finished']) {
            [$actions, $rows] = MatchOrders::auto($id, $state, $managers);
            $orders = [...$orders, ...$rows];
            [$state, $ball, $tick] = self::minute($state, $ball, $actions);
            $events = [...$events, ...self::tagged($tick)];
            $ms += $tick['moment']['ms'] + self::pause($tick, $state['cfg']['match'], $state, []);
        }
        foreach (array_chunk($orders, 200) as $chunk) {
            DB::table('match_actions')->insert($chunk);
        }
        MatchOrders::forget($id);
        self::save($id, $state, $events);
        // Bot against bot shows at its natural end; a long missed match is already over, so at once.
        DB::table('matches')->where('id', $id)->update(['status' => 'done', 'finished_at' => GameClock::now(),
            'publish_at' => $missed ? GameClock::now() : $from->copy()->addMilliseconds($ms)]);
    }

    /** Play every minute of one live match that is due now. Returns how many. */
    private static function play(int $id): int
    {
        $key = "league-match:{$id}";
        $live = Cache::get($key) ?? self::resume($id);
        // The runner was stopped but its cache kept: go on live from now, not in one burst to catch up.
        if ($live['next_at'] < GameClock::nowMs() - (int) config('game.matches.stalled_ms')) {
            $live['next_at'] = GameClock::nowMs();
        }
        // [UP17] Both coaches said they are ready: the window ends early.
        $resume = Cache::get("match-resume:{$id}");
        if ($resume && $resume['tick'] === $live['state']['tick'] && $resume['at'] < $live['next_at']) {
            $live['next_at'] = $resume['at'];
        }
        $n = 0;
        $timing = $live['state']['cfg']['match'];
        $fixture = self::fixtureOf($id);
        while (! $live['state']['finished'] && GameClock::nowMs() + self::lead() >= $live['next_at'] && $n < 120) {
            $next = $live['state']['tick'] + 1;
            // After a restart the minutes already made are made again with the orders they had; then new ones.
            $actions = isset($live['redo']) && $next <= $live['redo_until']
                ? ($live['redo'][$next] ?? [])
                : MatchOrders::forMinute($id, $live['state'], MatchOrders::managers($id, $live['control']));
            [$state, $ball, $tick] = self::minute($live['state'], $live['ball'], $actions);
            $tick['at'] = $live['next_at'];
            // [E8.3] L1: the minute's place on the match's own clock, and when the server made it.
            $tick['match_time'] = MatchMinute::matchTime($tick['tick']);
            $tick['server_ts'] = GameClock::nowMs();
            $live['state'] = $state;
            $live['ball'] = $ball;
            $live['events'] = [...$live['events'], ...self::tagged($tick)];
            $live['recent'] = array_slice([...$live['recent'], $tick], -20);
            $coaches = array_keys(array_filter(MatchOrders::managers($id, $live['control']), fn ($who) => $who === 'coach'));
            $pause = self::pause($tick, $timing, $state, $coaches);
            // The break from the end of the minute's scene to the next minute, for the ready button [UP17].
            $live['pause'] = ['tick' => $state['tick'], 'from' => $live['next_at'] + $tick['moment']['ms'], 'coaches' => $coaches];
            $live['next_at'] += $tick['moment']['ms'] + $pause;
            $live['pause']['until'] = $live['next_at'];
            $n++;
            MatchMinute::dispatch($fixture, $id, Simulator::redact($tick, null));
            $live['said'] = self::readings($id, $fixture, $state, $tick, $live['control'], $live['said'] ?? null);
            $halftime = collect($tick['events'])->contains(fn ($e) => $e['type'] === 'period' && $e['name'] === 'halftime');
            if ($halftime || $state['finished']) {
                self::save($id, $state, $live['events']);
                $live['events'] = [];
            }
        }
        DB::table('matches')->where('id', $id)->update(['next_at' => $live['next_at'], 'tick' => $live['state']['tick']]);
        Cache::forever($key, $live);
        if ($live['state']['finished']) {
            DB::table('matches')->where('id', $id)->update(['status' => 'done', 'publish_at' => GameClock::now(), 'finished_at' => GameClock::now()]);
            self::publish($id);
            Cache::put($key, $live, 7200);
        }

        return $n;
    }

    /**
     * The first minute, or the runner was stopped and its cache lost: back to the last saved state, playing on
     * from now. The orders that went in after it go in again at the same minutes, so nothing changes.
     */
    /**
     * The assistant's live reading for each coach [ENGINE 8.2]: from MatchFacts only, kept (a minute made again
     * after a restart gives it once) and sent on the club's own channel. Returns what each side was told.
     */
    private static function readings(int $id, object $f, array $state, array $tick, array $control, ?array $said): array
    {
        $said ??= self::said($id, $f);
        foreach (['home', 'away'] as $side) {
            if ($control[$side] !== 'coach') {
                continue;
            }
            $club = $side === 'home' ? $f->home_id : $f->away_id;
            // [UP2] The note in its coach's language.
            $locale = DB::table('clubs')->join('users', 'users.id', '=', 'clubs.user_id')->where('clubs.id', $club)->value('users.locale') ?? 'ar';
            [$reading, $said[$side]] = Readings::next(MatchFacts::of($state, $side), $tick['events'], $said[$side] ?? [], $locale);
            if (! $reading) {
                continue;
            }
            $new = DB::table('match_readings')->insertOrIgnore(['match_id' => $id, 'club_id' => $club, 'tick' => $reading['tick'],
                'minute' => min(255, $reading['minute']), 'kind' => $reading['kind'], 'text' => $reading['text'], 'created_at' => GameClock::now()]);
            if ($new) {
                ClubReading::dispatch($club, $id, $reading);
            }
        }

        return $said;
    }

    /** What each coach was told so far, from the kept readings (the cache was lost). */
    private static function said(int $id, object $f): array
    {
        $said = ['home' => [], 'away' => []];
        foreach (DB::table('match_readings')->where('match_id', $id)->orderBy('tick')->get() as $r) {
            $side = $r->club_id === $f->home_id ? 'home' : 'away';
            $said[$side][$r->kind] = $r->minute;
            $said[$side]['last'] = $r->minute;
        }

        return $said;
    }

    private static function resume(int $id): array
    {
        $m = DB::table('matches')->where('id', $id)->first();
        $state = json_decode($m->state, true);
        $redo = array_filter(MatchOrders::byTick($id), fn ($t) => $t > $state['tick'], ARRAY_FILTER_USE_KEY);

        return ['state' => $state, 'ball' => [525, 340], 'events' => [], 'recent' => [], 'next_at' => GameClock::nowMs(),
            'control' => MatchOrders::control(DB::table('fixtures')->where('id', $m->fixture_id)->first()),
            'redo' => $redo, 'redo_until' => $redo ? max(array_keys($redo)) : 0];
    }

    /** One minute, as the simulator plays it: the engine, then the frames and the scene's length. */
    private static function minute(array $state, array $ball, array $actions = []): array
    {
        $state = Runner::tick($state, $actions);
        $choreo = MatchChoreographer::frames($state, $state['out'], $ball);
        // The engine's debug values are for the simulator's developer panel only. A rejected order reaches
        // its own coach only (Simulator::redact), never the broadcast.
        $tick = array_diff_key(Commentary::annotate($state, $state['out']), ['debug' => 1]) + ['frames' => $choreo['frames'], 'teams' => Simulator::teams($state),
            'moment' => $m = MomentClock::moment($state['out']['events'], $state['cfg']['match'], (int) ($state['out']['period'] ?? 1)),
            'voice' => Voice::for($state['out']['events'], $m['kind'], (int) $state['seed'], (int) $state['out']['tick']),
            // [X42] Play stops after this minute: the coach's window.
            'window' => CoachWindows::window($state['out'], $state['cfg']['match']),
            // [Sprint 26 B1] How each side's coach feels after it; the screens only draw it.
            'moods' => Mood::forTick($state['out']['events'], $state['score'], $state['out']['minute'] ?? 0, (int) config('game.characters.late_minute'))];

        return [$state, $choreo['ball'], $tick];
    }

    /** [UP17] With no coach of its own watching, a window lasts as long as the computer takes to be ready. */
    private static function pause(array $tick, array $timing, array $state, array $coaches): int
    {
        $ms = CoachWindows::pauseMs($tick, $timing, $state, $coaches);
        $break = collect($tick['events'] ?? [])->contains(fn ($e) => $e['type'] === 'period');

        return $ms > 0 && ! $coaches && ! $break && isset($timing['ready_bot_ms']) ? min($ms, (int) $timing['ready_bot_ms']) : $ms;
    }

    /**
     * [UP17] A coach is ready: once every coach of the match is (a computer's side always is), the break ends now.
     * Returns the sides ready and when play goes on.
     */
    public static function ready(int $id, string $side): array
    {
        $live = Cache::get("league-match:{$id}");
        $pause = $live['pause'] ?? null;
        abort_unless($pause && $pause['until'] > $pause['from'] && ! $live['state']['finished'] && $pause['tick'] === $live['state']['tick'] && GameClock::nowMs() < $live['next_at'], 409, 'لا توقف الآن.');
        $key = "match-ready:{$id}:{$pause['tick']}";
        $ready = array_values(array_unique([...Cache::get($key, []), $side]));
        Cache::put($key, $ready, 600);
        $at = $live['next_at'];
        if (! array_diff($pause['coaches'], $ready)) {
            $at = max(GameClock::nowMs() + 1000, $pause['from']);
            Cache::put("match-resume:{$id}", ['tick' => $pause['tick'], 'at' => $at], 600);
            DB::table('matches')->where('id', $id)->where('next_at', '>', $at)->update(['next_at' => $at]);
        }

        return ['ready' => $ready, 'resume_at' => $at];
    }

    /** [UP17] The break under way, for the screens: until when, who is ready, and whose injured player waits. */
    public static function pauseOf(int $id): ?array
    {
        $live = Cache::get("league-match:{$id}");
        $pause = $live['pause'] ?? null;
        if (! $pause || $pause['until'] <= $pause['from'] || $live['state']['finished'] || $pause['tick'] !== $live['state']['tick'] || GameClock::nowMs() >= $live['next_at']) {
            return null;
        }

        $resume = Cache::get("match-resume:{$id}");
        $until = $resume && $resume['tick'] === $pause['tick'] ? min($live['next_at'], $resume['at']) : $live['next_at'];

        return ['until' => $until, 'ready' => Cache::get("match-ready:{$id}:{$pause['tick']}", []),
            'window' => CoachWindows::open($live['state']),
            'injured' => (object) array_map(fn ($side) => (int) $live['state']['teams'][$side]['pending_injury'], array_combine(CoachWindows::injured($live['state']), CoachWindows::injured($live['state'])))];
    }

    private static function tagged(array $tick): array
    {
        // The minute as shown: 45+2 counts as 47.
        $minute = is_array($tick['minute']) ? $tick['minute'][0] + $tick['minute'][1] : (int) $tick['minute'];

        return array_map(fn ($e) => ['tick' => $tick['tick'], 'minute' => $minute] + $e, $tick['events']);
    }

    /** Write the state and the events so far (half-time and the end). */
    private static function save(int $id, array $state, array $events): void
    {
        $m = DB::table('matches')->where('id', $id)->first();
        $f = DB::table('fixtures')->where('id', $m->fixture_id)->first();
        $club = ['home' => $f->home_id, 'away' => $f->away_id];
        $rows = array_map(fn ($e) => [
            'match_id' => $id, 'tick' => $e['tick'], 'minute' => min(255, (int) $e['minute']), 'type' => $e['type'],
            'club_id' => isset($e['team']) ? ($club[$e['team']] ?? null) : null,
            'player_id' => self::playerOf($e), 'payload' => json_encode(array_diff_key($e, ['tick' => 1, 'minute' => 1, 'type' => 1, 'team' => 1])),
        ], $events);
        DB::transaction(function () use ($id, $state, $rows) {
            foreach (array_chunk($rows, 200) as $chunk) {
                DB::table('match_events')->insert($chunk);
            }
            DB::table('matches')->where('id', $id)->update(['state' => json_encode($state), 'tick' => $state['tick'],
                'home_goals' => $state['score']['home'], 'away_goals' => $state['score']['away'], 'updated_at' => GameClock::now()]);
        });
    }

    private static function playerOf(array $e): ?int
    {
        $id = $e['player'] ?? $e['scorer'] ?? $e['shooter'] ?? $e['taker'] ?? null;

        return is_int($id) && DB::table('players')->where('id', $id)->exists() ? $id : null;
    }

    private static function fixtureOf(int $matchId): object
    {
        return DB::table('fixtures')->join('matches', 'matches.fixture_id', '=', 'fixtures.id')->where('matches.id', $matchId)
            ->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->select('fixtures.*', 'seasons.league_id')->first();
    }

    /** Show a finished match: the fixture's result, the table, the cup, and its mark on the players. */
    public static function publish(int $id): bool
    {
        return DB::transaction(function () use ($id) {
            if (DB::table('matches')->where('id', $id)->where('status', 'done')->update(['status' => 'finished']) !== 1) {
                return false;
            }
            MatchResult::apply($id);

            return true;
        });
    }
}
