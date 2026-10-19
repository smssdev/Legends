<?php

namespace App\Simulator;

use App\Engine\Actions;
use App\Engine\AutoPick;
use App\Engine\Formations;
use App\Engine\MatchSetup;
use App\Models\MasterClub;
use App\Models\SimMatch;
use App\Models\SimRoom;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * The simulator (docs/MATCH_VIEW.md 8): same engine, same events and frames
 * as a league match. Solo matches: the client drives the clock (speed,
 * pause, skip). Live matches (two devices, one per coach): the server keeps
 * the clock and both screens poll it. The server computes every minute.
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
            'live' => $live ? ['next_at' => null, 'recent' => []] : null,
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
     */
    public function join(SimRoom $room, string $name, int $clubId): SimMatch
    {
        return DB::transaction(function () use ($room, $name, $clubId) {
            $claimed = SimRoom::whereKey($room->id)->whereNull('guest_name')
                ->update(['guest_name' => $name, 'guest_club_id' => $clubId, 'updated_at' => GameClock::now()]);
            if ($claimed !== 1) {
                throw ValidationException::withMessages(['room' => 'دخل صديق آخر هذه الغرفة.']);
            }
            $room->refresh();
            $match = $this->create([
                'home_id' => $room->host_club_id, 'away_id' => $clubId, 'mode' => 'live',
                'names' => ['home' => $room->host_name, 'away' => $name],
            ]);
            $room->update(['sim_match_id' => $match->id]);
            $this->start($match, (int) config('game.match.room_kickoff_ms'));

            return $match;
        });
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
            $due = array_values(array_filter($pending, fn ($o) => $o['target_tick'] <= $next));
            $pending = array_values(array_filter($pending, fn ($o) => $o['target_tick'] > $next));
            $actions = array_map(fn ($o) => array_diff_key($o, ['key' => 1, 'target_tick' => 1]), $due);
            foreach (['home', 'away'] as $side) {
                if (($match->control[$side] ?? 'cpu') === 'cpu' && isset($state['out'])) {
                    $actions = [...$actions, ...CpuCoach::orders($state, $side)];
                }
            }

            $state = Runner::tick($state, $actions);
            $applied = [...$applied, ...array_map(fn ($o) => $o + ['applied_tick' => $state['tick']], $due)];
            $choreo = MatchChoreographer::frames($state, $state['out'], $ball);
            $ball = $choreo['ball'];
            $ticks[] = $state['out'];
            $out[] = $state['out'] + ['frames' => $choreo['frames'], 'teams' => self::teams($state), 'moment' => MomentClock::moment($state['out']['events'], $state['cfg']['match'])];
        }

        $match->fill(compact('state', 'ball', 'pending', 'applied', 'ticks'))->save();

        return $out;
    }

    /** Starts a live match's clock a few seconds from now, so both screens are ready. */
    public function start(SimMatch $match, int $delayMs = 3000): void
    {
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
     * work and the other read the result.
     */
    public function sync(SimMatch $match, int $since): array
    {
        return DB::transaction(function () use ($match, $since) {
            $m = SimMatch::findOrFail($match->id);
            $live = $m->live;
            $now = GameClock::nowMs();
            $timing = $m->state['cfg']['match'];

            for ($n = 0; $live['next_at'] !== null && $now >= $live['next_at'] && ! $m->state['finished'] && $n < 300; $n++) {
                $tick = $this->advance($m, 1)[0];
                $live['recent'] = array_slice([...$live['recent'], $tick], -20);
                $live['next_at'] += $tick['moment']['ms'] + self::pauseMs($tick, $timing);
            }
            $m->live = $live;
            $m->save();

            $ticks = array_values(array_filter($live['recent'], fn ($t) => $t['tick'] > $since));

            return [
                'started' => $live['next_at'] !== null,
                'finished' => $m->state['finished'],
                'tick' => $m->state['tick'],
                'server_now' => $now,
                'next_at' => $m->state['finished'] ? null : $live['next_at'],
                // Older minutes were dropped from the buffer: the screen jumps to the latest.
                'gap' => $ticks && $ticks[0]['tick'] > $since + 1,
                'ticks' => $ticks,
            ];
        });
    }

    /** The break after a minute that ends a period. */
    private static function pauseMs(array $tick, array $timing): int
    {
        foreach ($tick['events'] as $e) {
            if ($e['type'] === 'period' && $e['name'] === 'halftime') {
                return $timing['halftime_seconds'] * 1000;
            }
            if ($e['type'] === 'period' && in_array($e['name'], ['extra_time', 'extra_time_half', 'penalties'], true)) {
                return ($timing['extra_time_break_seconds'] ?? 10) * 1000;
            }
        }

        return 0;
    }

    public function report(SimMatch $match, string $side = 'home'): array
    {
        return Report::build($match->state, $match->ticks ?? [], $side);
    }

    /** The match as the screen needs it at the start. */
    public function view(SimMatch $match): array
    {
        $s = $match->state;

        return [
            'id' => $match->id,
            'seed' => $match->seed,
            'competition' => $s['competition'],
            'referee' => $s['referee'],
            'venue' => $s['venue'],
            'control' => $match->control,
            'mode' => $match->live === null ? 'solo' : 'live',
            'started' => $match->live === null || $match->live['next_at'] !== null,
            'tick' => $s['tick'],
            'finished' => $s['finished'],
            'score' => $s['score'],
            'formations' => Formations::names(),
            'timing' => [
                'tick_ms' => (int) $s['cfg']['match']['tick_ms'],
                'extra_time_tick_ms' => (int) $s['cfg']['match']['extra_time_tick_ms'],
                'halftime_seconds' => (int) $s['cfg']['match']['halftime_seconds'],
            ],
            'clubs' => ['home' => $s['teams']['home']['club'], 'away' => $s['teams']['away']['club']],
            'coaches' => (object) ($match->setup['names'] ?? []),
            'teams' => self::teams($s),
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
