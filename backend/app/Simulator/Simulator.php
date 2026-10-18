<?php

namespace App\Simulator;

use App\Engine\Actions;
use App\Engine\AutoPick;
use App\Engine\Formations;
use App\Engine\MatchSetup;
use App\Models\MasterClub;
use App\Models\SimMatch;
use Illuminate\Validation\ValidationException;

/**
 * The simulator (docs/MATCH_VIEW.md 8): same engine, same events and frames
 * as a league match, but the client drives the clock (speed, pause, skip).
 * The server still computes every minute.
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

        return SimMatch::create([
            'seed' => $seed,
            'setup' => $setup,
            'control' => ['home' => $in['control']['home'] ?? 'me', 'away' => $in['control']['away'] ?? 'cpu'],
            'state' => $state,
            'ticks' => [],
            'pending' => [],
            'applied' => [],
            'ball' => [525, 340],
        ]);
    }

    /** Queues an order for the next minute that has not been simulated yet. */
    public function order(SimMatch $match, array $order): array
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
            $out[] = $state['out'] + ['frames' => $choreo['frames'], 'teams' => self::teams($state)];
        }

        $match->fill(compact('state', 'ball', 'pending', 'applied', 'ticks'))->save();

        return $out;
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
