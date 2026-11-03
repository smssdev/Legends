<?php

namespace App\League;

use App\Characters\Mood;
use App\Simulator\Commentary;
use App\Simulator\MatchChoreographer;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use App\Simulator\Simulator;
use App\Simulator\Voice;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * A league match again [PLAN 2.12, Sprint 19 B3]: its starting state (seed and config snapshot inside) and the
 * orders at the minutes they went in give every minute as it was, with its frames, while the engine is the
 * same version. [X78] And the scene is kept when the match ends (match_replays), so it is watched the same after the
 * engine changes. A match from an older engine with no kept scene is shown from its stored events.
 */
class MatchReplay
{
    public static function replayable(object $match): bool
    {
        return (int) $match->engine_version === (int) config('game.engine.version')
            || DB::table('match_replays')->where('match_id', $match->id)->exists();
    }

    /**
     * [X78] Keep a finished match's scene, once, while its engine is this one (after it, the scene can no longer be
     * made). True when it is kept, now or before.
     */
    public static function keep(object $match): bool
    {
        if (DB::table('match_replays')->where('match_id', $match->id)->exists()) {
            return true;
        }
        if ($match->status !== 'finished' || (int) $match->engine_version !== (int) config('game.engine.version')) {
            return false;
        }
        $packed = base64_encode((string) gzencode(json_encode(self::make($match), JSON_UNESCAPED_UNICODE), 6));
        DB::table('match_replays')->insertOrIgnore(['match_id' => $match->id, 'engine_version' => (int) $match->engine_version,
            'bytes' => strlen($packed), 'ticks' => $packed, 'created_at' => GameClock::now()]);

        return true;
    }

    /** [X78] The kept scene, or null. */
    public static function kept(int $matchId): ?array
    {
        $packed = DB::table('match_replays')->where('match_id', $matchId)->value('ticks');

        return $packed === null ? null : json_decode((string) gzdecode(base64_decode($packed)), true);
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

    /** Every minute as the viewer plays it: the frames, the players' numbers and the scene's length (kept, or made now). */
    public static function ticks(object $match): array
    {
        return self::kept((int) $match->id) ?? self::make($match);
    }

    private static function make(object $match): array
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
                'moment' => $m = MomentClock::moment($state['out']['events'], $state['cfg']['match'], (int) ($state['out']['period'] ?? 1), (int) $state['seed']),
                'voice' => Voice::for($state['out']['events'], $m['kind'], (int) $state['seed'], (int) $state['out']['tick']),
                'moods' => Mood::forTick($state['out']['events'], $state['score'], $state['out']['minute'] ?? 0, (int) config('game.characters.late_minute'))];
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
