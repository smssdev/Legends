<?php

namespace App\Simulator;

use App\Data\ClubLogo;
use App\Engine\Actions;
use App\Engine\AutoPick;
use App\Engine\Formations;
use App\Engine\MatchSetup;
use App\Models\MasterClub;
use App\Models\SimMatch;
use App\Models\SimRoom;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/**
 * The simulator (docs/MATCH_VIEW.md 8): same engine, same events and frames
 * as a league match. Solo matches: the client drives the clock (speed,
 * pause, skip). Live matches (two devices, one per coach): the server keeps
 * the clock and both screens poll it. The server computes every minute.
 * In a live match each coach holds a secret seat: only it gives orders for
 * its side, and the other side's tactics never reach it.
 */
class Simulator
{
    public function create(array $in): SimMatch
    {
        $home = MasterClub::findOrFail($in['home_id']);
        $away = MasterClub::findOrFail($in['away_id']);
        $seed = (int) ($in['seed'] ?? random_int(1, 999999));
        $setup = [
            'home_id' => $home->id, 'away_id' => $away->id,
            // The coaches' names in a match between friends (shown on the scoreboard).
            'names' => array_filter(['home' => $in['names']['home'] ?? null, 'away' => $in['names']['away'] ?? null]),
            'options' => [
                'seed' => $seed,
                'competition' => $in['competition'] ?? 'league',
                'referee' => (int) ($in['referee'] ?? 1),
                'venue' => $in['venue'] ?? 'home',
            ],
            'overrides' => [
                'home' => array_filter(['formation' => $in['home']['formation'] ?? null, 'tactics' => $in['home']['tactics'] ?? null]),
                'away' => array_filter(['formation' => $in['away']['formation'] ?? null, 'tactics' => $in['away']['tactics'] ?? null]),
            ],
        ];
        foreach (['home', 'away'] as $side) {
            if (isset($setup['overrides'][$side]['tactics']) && ! Actions::validTactics($setup['overrides'][$side]['tactics'])) {
                throw ValidationException::withMessages(["$side.tactics" => 'تكتيك غير صالح.']);
            }
        }

        $state = MatchFactory::make($home, $away, $setup['options'], $setup['overrides']);

        $live = ($in['mode'] ?? 'solo') === 'live';

        return SimMatch::create([
            'seed' => $seed,
            'setup' => $setup,
            'control' => $live ? ['home' => 'me', 'away' => 'me'] : ['home' => $in['control']['home'] ?? 'me', 'away' => $in['control']['away'] ?? 'cpu'],
            'live' => $live ? ['next_at' => null, 'recent' => [], 'reactions' => []] : null,
            'seats' => $live ? ['home' => $in['seats']['home'] ?? self::newSeat(), 'away' => $in['seats']['away'] ?? self::newSeat()] : null,
            'state' => $state,
            'ticks' => [],
            'pending' => [],
            'applied' => [],
            'ball' => [525, 340],
        ]);
    }

    /**
     * A friend joins a room: the guest's club and name are claimed with one
     * conditional update (SQLite: no row locks), then the live match is made
     * and kicks off once both screens have had time to show the preview.
     * Returns the guest's seat: the host already holds the home one.
     */
    public function join(SimRoom $room, string $name, int $clubId): string
    {
        return DB::transaction(function () use ($room, $name, $clubId) {
            $claimed = SimRoom::whereKey($room->id)->whereNull('guest_name')
                ->update(['guest_name' => $name, 'guest_club_id' => $clubId, 'updated_at' => GameClock::now()]);
            if ($claimed !== 1) {
                throw ValidationException::withMessages(['room' => 'دخل صديق آخر هذه الغرفة.']);
            }
            $room->refresh();
            $seat = self::newSeat();
            $match = $this->create([
                'home_id' => $room->host_club_id, 'away_id' => $clubId, 'mode' => 'live',
                'names' => ['home' => $room->host_name, 'away' => $name],
                'seats' => ['home' => $room->host_seat ?? self::newSeat(), 'away' => $seat],
            ]);
            $room->update(['sim_match_id' => $match->id]);
            $this->start($match);

            return $seat;
        });
    }

    public static function newSeat(): string
    {
        return Str::random(40);
    }

    /** The side a seat manages in a live match, or null (a viewer, or a solo match). */
    public static function seatSide(SimMatch $match, ?string $seat): ?string
    {
        foreach ($match->seats ?? [] as $side => $secret) {
            if ($seat !== null && $seat !== '' && hash_equals($secret, $seat)) {
                return $side;
            }
        }

        return null;
    }

    /**
     * What one side may see of a live minute: the other side's tactics and
     * its orders' details stay hidden (CLAUDE.md, privacy in a match).
     * $you is null for a viewer, who sees neither side's tactics.
     */
    public static function redact(array $data, ?string $you): array
    {
        foreach (['home', 'away'] as $side) {
            if ($side !== $you && isset($data['teams'][$side])) {
                $data['teams'][$side]['tactics'] = null;
            }
        }
        if (isset($data['events'])) {
            $data['events'] = array_map(function ($e) use ($you) {
                if ($e['type'] === 'action' && ($e['team'] ?? null) !== $you) {
                    unset($e['action']['tactics']);
                }

                return $e;
            }, $data['events']);
        }
        if (isset($data['rejected'])) {
            $data['rejected'] = array_values(array_filter($data['rejected'], fn ($r) => ($r['action']['team'] ?? null) === $you));
        }

        return $data;
    }

    /** Queues an order for the next minute that has not been simulated yet. */
    public function order(SimMatch $match, array $order): array
    {
        // Re-read inside a write transaction: a live match may be advancing right now.
        return DB::transaction(fn () => $this->queue(SimMatch::findOrFail($match->id), $order));
    }

    private function queue(SimMatch $match, array $order): array
    {
        $keys = array_column(array_merge($match->pending ?? [], $match->applied ?? []), 'key');
        if (in_array($order['key'], $keys, true)) {
            return ['target_tick' => $match->state['tick'] + 1, 'duplicate' => true];
        }
        // [X42] A live match takes a coach's change in a window only.
        abort_if($match->live !== null && ! CoachWindows::open($match->state), 409, 'التغيير في فترات التوقف فقط: قبل البداية، وفي الدقائق 15 و30 و60 و75، وفي الاستراحة.');
        $target = $match->state['tick'] + 1;
        $match->pending = [...($match->pending ?? []), $order + ['target_tick' => $target]];
        $match->save();

        return ['target_tick' => $target, 'duplicate' => false];
    }

    /** Simulates up to $count minutes and returns each with its frames. */
    public function advance(SimMatch $match, int $count): array
    {
        $state = $match->state;
        $ball = $match->ball;
        $pending = $match->pending ?? [];
        $applied = $match->applied ?? [];
        $ticks = $match->ticks ?? [];
        $out = [];

        for ($i = 0; $i < $count && ! $state['finished']; $i++) {
            $next = $state['tick'] + 1;
            // [X42] Live, the orders go in after a window only (one that came as it closed waits for the next).
            $open = $match->live === null || CoachWindows::open($state);
            $due = $open ? array_values(array_filter($pending, fn ($o) => $o['target_tick'] <= $next)) : [];
            $pending = $open ? array_values(array_filter($pending, fn ($o) => $o['target_tick'] > $next)) : $pending;
            $actions = array_map(fn ($o) => array_diff_key($o, ['key' => 1, 'target_tick' => 1]), $due);
            foreach (['home', 'away'] as $side) {
                if (($match->control[$side] ?? 'cpu') === 'cpu' && isset($state['out']) && $open) {
                    $actions = [...$actions, ...CpuCoach::orders($state, $side)];
                }
            }

            $state = Runner::tick($state, $actions);
            $applied = [...$applied, ...array_map(fn ($o) => $o + ['applied_tick' => $state['tick']], $due)];
            $choreo = MatchChoreographer::frames($state, $state['out'], $ball);
            $ball = $choreo['ball'];
            $ticks[] = $state['out'];
            $out[] = Commentary::annotate($state, $state['out']) + ['frames' => $choreo['frames'], 'teams' => self::teams($state), 'moment' => $m = MomentClock::moment($state['out']['events'], $state['cfg']['match'], (int) ($state['out']['period'] ?? 1)),
                'voice' => Voice::for($state['out']['events'], $m['kind'], (int) $state['seed'], (int) $state['out']['tick']),
                'window' => $match->live !== null && CoachWindows::window($state['out'], $state['cfg']['match'])];
        }

        $match->fill(compact('state', 'ball', 'pending', 'applied', 'ticks'))->save();

        return $out;
    }

    /** Starts a live match's clock: kick-off after the pre-match break (game.match.kickoff_ms). */
    public function start(SimMatch $match, ?int $delayMs = null): void
    {
        $delayMs ??= (int) config('game.match.kickoff_ms');
        DB::transaction(function () use ($match, $delayMs) {
            $m = SimMatch::findOrFail($match->id);
            if ($m->live !== null && $m->live['next_at'] === null) {
                $m->live = ['next_at' => GameClock::nowMs() + $delayMs] + $m->live;
                $m->save();
            }
        });
    }

    /**
     * Live matches: simulates every minute that is due by the clock, then
     * returns the minutes after $since that are still kept with their frames.
     * Both screens call this; the write transaction makes one of them do the
     * work and the other read the result. A minute is made a little before it
     * starts (live_lead_ms) and carries its start time on the server clock
     * (at), so both screens play it at the same instant, neither ahead nor
     * behind. $you is the side of the screen asking (redact()).
     */
    public function sync(SimMatch $match, int $since, ?string $you = null): array
    {
        return DB::transaction(function () use ($match, $since, $you) {
            $m = SimMatch::findOrFail($match->id);
            $live = $m->live;
            $now = GameClock::nowMs();
            $timing = $m->state['cfg']['match'];
            $lead = (int) ($timing['live_lead_ms'] ?? 0);

            for ($n = 0; $live['next_at'] !== null && $now + $lead >= $live['next_at'] && ! $m->state['finished'] && $n < 300; $n++) {
                $tick = $this->advance($m, 1)[0] + ['at' => $live['next_at']];
                $live['recent'] = array_slice([...$live['recent'], $tick], -20);
                $live['next_at'] += $tick['moment']['ms'] + self::pauseMs($tick, $timing);
            }
            $m->live = $live;
            $m->save();

            $ticks = array_values(array_filter($live['recent'], fn ($t) => $t['tick'] > $since));
            $now = self::playing($m, $now);

            return [
                'started' => $live['next_at'] !== null,
                'finished' => $now['finished'],
                'tick' => $now['tick'],
                'server_now' => $now['ms'],
                'next_at' => $m->state['finished'] ? null : $live['next_at'],
                // Older minutes were dropped from the buffer: the screen jumps to the latest.
                'gap' => $ticks && $ticks[0]['tick'] > $since + 1,
                'ticks' => array_map(fn ($t) => self::redact($t, $you), $ticks),
                // The coaches' reactions of the last few seconds (each screen keeps the ids it has shown).
                'reactions' => array_values(array_filter($live['reactions'] ?? [], fn ($r) => $r['at'] >= $now['ms'] - 8000)),
            ];
        });
    }

    /**
     * The minute a live match is playing at $ms: minutes made ahead of time
     * do not count yet, so their score and their end stay unknown.
     */
    private static function playing(SimMatch $m, int $ms): array
    {
        $s = $m->state;
        $recent = $m->live['recent'] ?? [];
        $ahead = array_values(array_filter($recent, fn ($t) => ($t['at'] ?? 0) > $ms));
        if (! $ahead) {
            return ['ms' => $ms, 'tick' => $s['tick'], 'score' => $s['score'], 'finished' => $s['finished']];
        }
        $before = array_values(array_filter($recent, fn ($t) => ($t['at'] ?? 0) <= $ms));

        return [
            'ms' => $ms, 'tick' => $ahead[0]['tick'] - 1, 'finished' => false,
            'score' => $before ? end($before)['score'] : ['home' => 0, 'away' => 0],
        ];
    }

    /**
     * A coach reacts (a cheer, a taunt): both screens show it on their next
     * sync. At most one every reaction_gap_ms per side.
     */
    public function react(SimMatch $match, string $side, string $key): array
    {
        return DB::transaction(function () use ($match, $side, $key) {
            $m = SimMatch::findOrFail($match->id);
            $live = $m->live;
            $now = GameClock::nowMs();
            $list = $live['reactions'] ?? [];
            $mine = array_filter($list, fn ($r) => $r['side'] === $side);
            if ($mine && end($mine)['at'] > $now - (int) config('game.match.reaction_gap_ms')) {
                throw ValidationException::withMessages(['key' => 'تمهّل قليلاً.']);
            }
            $reaction = ['id' => ($list ? end($list)['id'] : 0) + 1, 'side' => $side, 'key' => $key, 'at' => $now];
            $live['reactions'] = array_slice([...$list, $reaction], -20);
            $m->live = $live;
            $m->save();

            return $reaction;
        });
    }

    /** The break after a minute: a period's end or a coach's window [X42]. */
    private static function pauseMs(array $tick, array $timing): int
    {
        return CoachWindows::pauseMs($tick, $timing);
    }

    public function report(SimMatch $match, string $side = 'home'): array
    {
        return Report::build($match->state, $match->ticks ?? [], $side);
    }

    /** The match as the screen needs it at the start; $you is the side of a live seat. */
    public function view(SimMatch $match, ?string $you = null): array
    {
        $s = $match->state;
        $live = $match->live !== null;
        $now = $live ? self::playing($match, GameClock::nowMs()) : $s;

        return [
            'id' => $match->id,
            'seed' => $match->seed,
            'competition' => $s['competition'],
            'referee' => $s['referee'],
            'venue' => $s['venue'],
            'control' => $match->control,
            'mode' => $live ? 'live' : 'solo',
            'you' => $you,
            'started' => ! $live || $match->live['next_at'] !== null,
            'tick' => $now['tick'],
            'finished' => $now['finished'],
            'score' => $now['score'],
            'formations' => Formations::names(),
            'timing' => [
                'tick_ms' => (int) $s['cfg']['match']['tick_ms'],
                'extra_time_tick_ms' => (int) $s['cfg']['match']['extra_time_tick_ms'],
                'halftime_seconds' => (int) $s['cfg']['match']['halftime_seconds'],
                // [X42] The coach's windows: a live match stops after these minutes for window_seconds.
                'windows' => $live ? ($s['cfg']['match']['windows'] ?? []) : [], 'window_seconds' => (int) ($s['cfg']['match']['window_seconds'] ?? 0),
            ],
            'clubs' => ['home' => ClubLogo::with($s['teams']['home']['club']), 'away' => ClubLogo::with($s['teams']['away']['club'])],
            'coaches' => (object) ($match->setup['names'] ?? []),
            'teams' => $live ? self::redact(['teams' => self::teams($s)], $you)['teams'] : self::teams($s),
            'slots' => [
                'home' => Formations::slots($s['teams']['home']['formation']),
                'away' => Formations::slots($s['teams']['away']['formation']),
            ],
        ];
    }

    /** Compact per-team snapshot after a minute: lineup, fitness, cards, tactics, stats. */
    public static function teams(array $s): array
    {
        $teams = [];
        foreach (['home', 'away'] as $side) {
            $t = $s['teams'][$side];
            $teams[$side] = [
                'formation' => $t['formation'],
                'tactics' => $t['tactics'],
                'subs_used' => $t['subs_used'],
                'subs_max' => $t['subs_max'],
                'stats' => $t['stats'],
                'players' => array_map(fn ($p) => [
                    'id' => $p['id'], 'name' => $p['name'], 'no' => $p['no'], 'pos' => $p['pos'], 'line' => $p['line'],
                    'slot' => $p['slot'], 'slot_line' => $p['slot_line'], 'on' => $p['on'], 'out' => $p['out'],
                    'fit' => intdiv($p['fit'], 100), 'yc' => $p['yc'], 'ovr' => $p['a']['ovr'], 'rating' => $p['st']['r'],
                ], $t['players']),
            ];
        }

        return $teams;
    }

    /** Club list entry with its best eleven, for the setup screen. */
    public function squad(MasterClub $club): array
    {
        $players = array_map(fn ($p) => MatchSetup::player($p), MatchFactory::squad($club));
        $pick = AutoPick::pick($players);

        return [
            'club' => MatchFactory::club($club),
            'formation' => $pick['formation'],
            'starters' => $pick['starters'],
            'bench' => $pick['bench'],
            'players' => array_map(fn ($p) => ['id' => $p['id'], 'name' => $p['name'], 'pos' => $p['pos'], 'line' => $p['line'],
                'age' => $p['age'], 'ovr' => $p['a']['ovr'], 'pac' => $p['a']['pac'], 'sho' => $p['a']['sho'], 'pas' => $p['a']['pas'],
                'dri' => $p['a']['dri'], 'def' => $p['a']['def'], 'phy' => $p['a']['phy']], $players),
        ];
    }
}
