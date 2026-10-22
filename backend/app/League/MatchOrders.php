<?php

namespace App\League;

use App\Simulator\CpuCoach;
use App\Support\GameClock;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * The orders of a league match [PLAN 2.12, docs/ENGINE.md 7]. Each side is managed by:
 *  - its coach, while he follows the match (his screen asked for it in the last assistant_after_ms);
 *  - his assistant when he is away, and the computer for a bot: the same simple rules (CpuCoach), given as
 *    ordinary orders.
 * Every order is kept in match_actions with the minute it really went in (applied_tick): one that arrives
 * while a minute is being made goes in the next. The seed, the starting state and these give the match again.
 */
class MatchOrders
{
    /** coach (a coach's club) or cpu (a bot), per side. */
    public static function control(object $fixture): array
    {
        $coached = DB::table('clubs')->whereIn('id', [$fixture->home_id, $fixture->away_id])->whereNotNull('user_id')->pluck('id')->all();

        return ['home' => in_array($fixture->home_id, $coached) ? 'coach' : 'cpu', 'away' => in_array($fixture->away_id, $coached) ? 'coach' : 'cpu'];
    }

    /** The coach's screen is on the match. */
    public static function watching(int $matchId, string $side): void
    {
        Cache::put("match-watch:{$matchId}:{$side}", GameClock::nowMs(), 600);
    }

    /** Who manages each side now: coach, assistant (the coach is away) or cpu. */
    public static function managers(int $matchId, array $control): array
    {
        $since = GameClock::nowMs() - (int) config('game.matches.assistant_after_ms');

        return array_map(fn ($side) => $control[$side] === 'cpu' ? 'cpu'
            : ((int) Cache::get("match-watch:{$matchId}:{$side}", 0) >= $since ? 'coach' : 'assistant'), ['home' => 'home', 'away' => 'away']);
    }

    /** A coach's order, for the next minute not yet made. False when this key was already given. */
    public static function give(int $matchId, string $side, ?int $userId, string $key, array $action, int $tick): bool
    {
        return DB::table('match_actions')->insertOrIgnore([
            'match_id' => $matchId, 'side' => $side, 'source' => 'coach', 'user_id' => $userId, 'idempotency_key' => $key,
            'target_tick' => $tick, 'action' => json_encode($action), 'created_at' => GameClock::now(),
        ]) === 1;
    }

    /** The orders that go into the next minute of $state, kept with it. */
    public static function forMinute(int $matchId, array $state, array $managers): array
    {
        $tick = $state['tick'] + 1;
        $rows = DB::table('match_actions')->where('match_id', $matchId)->whereNull('applied_tick')->where('target_tick', '<=', $tick)->orderBy('id')->get();
        if ($rows->isNotEmpty()) {
            DB::table('match_actions')->whereIn('id', $rows->pluck('id'))->update(['applied_tick' => $tick]);
        }
        $actions = $rows->map(fn ($r) => ['team' => $r->side] + json_decode($r->action, true))->all();
        [$auto, $kept] = self::auto($matchId, $state, $managers);
        if ($kept) {
            DB::table('match_actions')->insert($kept);
        }

        return [...$actions, ...$auto];
    }

    /** The assistant's and the computer's orders for the next minute, and their rows. */
    public static function auto(int $matchId, array $state, array $managers): array
    {
        $tick = $state['tick'] + 1;
        $actions = [];
        $rows = [];
        foreach ($managers as $side => $who) {
            if ($who === 'coach' || ! isset($state['out'])) {
                continue;
            }
            foreach (CpuCoach::orders($state, $side) as $i => $order) {
                $actions[] = $order;
                $rows[] = ['match_id' => $matchId, 'side' => $side, 'source' => $who, 'user_id' => null, 'idempotency_key' => "{$who}:{$tick}:{$side}:{$i}",
                    'target_tick' => $tick, 'applied_tick' => $tick, 'action' => json_encode(array_diff_key($order, ['team' => 1])), 'created_at' => GameClock::now()];
            }
        }

        return [$actions, $rows];
    }

    /** Every order that went in, by minute: what a replay gives the engine. */
    public static function byTick(int $matchId): array
    {
        $out = [];
        foreach (DB::table('match_actions')->where('match_id', $matchId)->whereNotNull('applied_tick')->orderBy('id')->get() as $r) {
            $out[$r->applied_tick][] = ['team' => $r->side] + json_decode($r->action, true);
        }

        return $out;
    }
}
