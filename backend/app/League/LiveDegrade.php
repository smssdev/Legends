<?php

namespace App\League;

use App\Support\GameClock;
use Illuminate\Support\Facades\Cache;

/**
 * The live broadcast's degradation ladder [Sprint 21 E8.7]: when the server is short of breath, the live matches
 * give up their extras in this order, never the match itself (the minutes, the score and the orders always go on):
 *
 *   0  everything (normal).
 *   1  no summary: a screen back after a gap jumps to now without the summary and the missed minutes' events.
 *   2  and no voice: the commentator's line leaves the minute (the written events stay).
 *   3  and less often: the screens are told to poll every poll_ms (config) instead of about once a second.
 *
 * The level is what `matches:degrade` set for now, or else the higher of game.live.degrade.level (env
 * GAME_DEGRADE_LEVEL) and the automatic level [Sprint 20 S6, the owner's decision 2026-10-29]: the runner reports how
 * late each step played its due minutes (or how long the step took, whichever is worse), the load is a smoothed
 * average of that, and crossing auto.up_ms[n] raises the level to n+1 at once. It comes down one step at a time,
 * only after the load stayed under half of the level's own threshold for auto.hold_s seconds, so it never flaps.
 */
class LiveDegrade
{
    public const MAX = 3;

    public static function level(): int
    {
        $set = Cache::get('live-degrade');

        return max(0, min(self::MAX, (int) ($set ?? max((int) config('game.live.degrade.level'), self::auto()))));
    }

    /** The automatic level, 0 when it is switched off. */
    public static function auto(): int
    {
        return config('game.live.degrade.auto.enabled') ? (int) (Cache::get('live-degrade-auto')['level'] ?? 0) : 0;
    }

    /** The smoothed load in ms (what the automatic level reads). */
    public static function load(): int
    {
        return (int) (Cache::get('live-degrade-auto')['load'] ?? 0);
    }

    /**
     * One runner step's lateness in ms [S6]: folded into the smoothed load (three parts the old, one part the new),
     * then the automatic level goes up at once past a threshold, or down one step after a calm hold.
     */
    public static function observe(int $lateMs): int
    {
        $cfg = config('game.live.degrade.auto');
        $now = GameClock::nowMs();
        $s = Cache::get('live-degrade-auto') ?? ['load' => 0, 'level' => 0, 'calm_since' => null];
        $s['load'] = intdiv($s['load'] * 3 + max(0, $lateMs), 4);
        $up = array_map('intval', $cfg['up_ms']);
        $target = 0;
        foreach ($up as $i => $threshold) {
            if ($s['load'] >= $threshold) {
                $target = $i + 1;
            }
        }
        if ($target > $s['level']) {
            $s['level'] = min(self::MAX, $target);
            $s['calm_since'] = null;
        } elseif ($s['level'] > 0 && $s['load'] < intdiv($up[$s['level'] - 1], 2)) {
            $s['calm_since'] ??= $now;
            if ($now - $s['calm_since'] >= (int) $cfg['hold_s'] * 1000) {
                $s['level']--;
                $s['calm_since'] = $s['level'] > 0 ? $now : null;
            }
        } else {
            $s['calm_since'] = null;
        }
        Cache::put('live-degrade-auto', $s, 3600);

        return $s['level'];
    }

    /** Set the level for the next hours (null goes back to the config's). */
    public static function set(?int $level, int $hours = 6): void
    {
        $level === null ? Cache::forget('live-degrade') : Cache::put('live-degrade', max(0, min(self::MAX, $level)), $hours * 3600);
    }

    public static function summary(): bool
    {
        return self::level() < 1;
    }

    public static function voice(): bool
    {
        return self::level() < 2;
    }

    /** How long the screens wait between two polls, or null for their own pace. */
    public static function pollMs(): ?int
    {
        return self::level() >= 3 ? (int) config('game.live.degrade.poll_ms') : null;
    }
}
