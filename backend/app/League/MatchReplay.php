<?php

namespace App\League;

use App\Simulator\Commentary;
use App\Simulator\MatchChoreographer;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use App\Simulator\Simulator;
use App\Simulator\Voice;
use Illuminate\Support\Facades\DB;

/**
 * A league match again [PLAN 2.12, Sprint 19 B3]: its starting state (seed and config snapshot inside) and the
 * orders at the minutes they went in give every minute as it was, with its frames, while the engine is the
 * same version. A match from an older engine is shown from its stored events.
 */
class MatchReplay
{
    public static function replayable(object $match): bool
    {
        return (int) $match->engine_version === (int) config('game.engine.version');
    }

    /** The final state and every minute (the engine's output), as the match was played. */
    public static function run(object $match): array
    {
        $state = json_decode($match->initial_state, true);
        $orders = MatchOrders::byTick($match->id);
        $ticks = [];
        while (! $state['finished'] && count($ticks) < 200) {
            $state = Runner::tick($state, $orders[$state['tick'] + 1] ?? []);
            $ticks[] = $state['out'];
        }

        return [$state, $ticks];
    }

    /** Every minute as the viewer plays it: the frames, the players' numbers and the scene's length. */
    public static function ticks(object $match): array
    {
        $state = json_decode($match->initial_state, true);
        $orders = MatchOrders::byTick($match->id);
        $ball = [525, 340];
        $out = [];
        while (! $state['finished'] && count($out) < 200) {
            $state = Runner::tick($state, $orders[$state['tick'] + 1] ?? []);
            $choreo = MatchChoreographer::frames($state, $state['out'], $ball);
            $ball = $choreo['ball'];
            $out[] = array_diff_key(Commentary::annotate($state, $state['out']), ['debug' => 1]) + ['frames' => $choreo['frames'], 'teams' => Simulator::teams($state),
                'moment' => $m = MomentClock::moment($state['out']['events'], $state['cfg']['match'], (int) ($state['out']['period'] ?? 1)),
                'voice' => Voice::for($state['out']['events'], $m['kind'], (int) $state['seed'], (int) $state['out']['tick'])];
        }

        return $out;
    }

    /** An older engine's match: its stored events, minute by minute. */
    public static function events(int $matchId): array
    {
        $clubs = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')->where('matches.id', $matchId)
            ->select('fixtures.home_id', 'fixtures.away_id')->first();

        return DB::table('match_events')->where('match_id', $matchId)->orderBy('id')->get()
            ->map(fn ($e) => ['tick' => $e->tick, 'minute' => $e->minute, 'type' => $e->type,
                'team' => $e->club_id === null ? null : ($e->club_id === $clubs->home_id ? 'home' : 'away')] + json_decode($e->payload, true))->all();
    }
}
