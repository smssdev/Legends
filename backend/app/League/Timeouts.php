<?php

namespace App\League;

use App\Events\MatchTimeout;
use App\Support\GameClock;
use App\Support\LiveEvents;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 50 M14] The timeout: once a match, each coach of a live league match may stop play for
 * game.match.timeout_seconds. The match itself is not changed (the engine plays the same minutes, with the orders
 * the coaches give): only the next minute starts later, for every screen, as the ready button's window does the other
 * way (MatchRunner reads the hold). While it lasts, both coaches may change the line-up and the tactics as in a window.
 */
class Timeouts
{
    public static function call(object $match, string $side): array
    {
        if ($match->mode !== 'live' || $match->status !== 'live') {
            throw new HttpException(409, __('انتهت المباراة.'));
        }
        $live = Cache::get("league-match:{$match->id}");
        $tick = (int) ($live['state']['tick'] ?? $match->tick);
        if (! empty($live['state']['finished'])) {
            throw new HttpException(409, __('انتهت المباراة.'));
        }
        $from = max((int) ($live['next_at'] ?? $match->next_at ?? 0), GameClock::nowMs());
        $until = $from + 1000 * (int) config('game.match.timeout_seconds');
        DB::transaction(function () use ($match, $side, $tick, $until) {
            if (DB::table('match_timeouts')->insertOrIgnore(['match_id' => $match->id, 'side' => $side, 'tick' => $tick, 'until_ms' => $until, 'created_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, __('أخذت وقتك المستقطع في هذه المباراة.'));
            }
            DB::table('matches')->where('id', $match->id)->where('status', 'live')->update(['next_at' => $until]);
        });
        // The runner keeps its own next minute in the cache: it waits for the hold (the later of the two).
        $hold = Cache::get("match-hold:{$match->id}");
        Cache::put("match-hold:{$match->id}", ['tick' => $tick, 'until' => max($until, (int) ($hold['until'] ?? 0))], 7200);
        $view = ['side' => $side, 'tick' => $tick, 'until' => $until, 'seconds' => (int) config('game.match.timeout_seconds')];
        LiveEvents::send(new MatchTimeout($match->id, $view));

        return $view;
    }

    /** Whether a timeout holds play now in this match. */
    public static function active(int $matchId): bool
    {
        return DB::table('match_timeouts')->where('match_id', $matchId)->where('until_ms', '>', GameClock::nowMs())->exists();
    }

    /** The match's timeouts, for its page and its replay. */
    public static function of(int $matchId): array
    {
        return DB::table('match_timeouts')->where('match_id', $matchId)->orderBy('id')->get(['side', 'tick', 'until_ms'])
            ->map(fn ($t) => ['side' => $t->side, 'tick' => (int) $t->tick, 'until' => (int) $t->until_ms])->all();
    }

    /** The runner's next minute, held by a timeout called at this minute. */
    public static function hold(int $matchId, int $tick, int $nextAt): int
    {
        $hold = Cache::get("match-hold:{$matchId}");

        return $hold && $hold['tick'] === $tick && $hold['until'] > $nextAt ? (int) $hold['until'] : $nextAt;
    }
}
