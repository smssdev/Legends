<?php

namespace App\Admin;

use App\Support\GameClock;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Queue;
use Throwable;

/**
 * [Sprint 66 B3] The server's pulse for the admin panel, from counters in the cache (Redis on our server, Sprint 52):
 * how fast the live match answers (GET /matches/{id}/live, its median and its 95th percentile over the last five
 * minutes), how many jobs wait in the queue, and how many sockets Reverb holds. Each part says null when it cannot be
 * read (no Reverb in development), never an error in the panel.
 */
final class ServerPulse
{
    public const WINDOW_MINUTES = 5;

    /** Samples kept a minute at most (a busy minute keeps its first ones: enough for a percentile). */
    public const PER_MINUTE = 600;

    private static function key(int $minute): string
    {
        return "pulse:live:{$minute}";
    }

    /** One live answer's time, in milliseconds. */
    public static function record(int $ms): void
    {
        $minute = intdiv(GameClock::nowMs(), 60_000);
        try {
            $list = Cache::get(self::key($minute), []);
            if (count($list) < self::PER_MINUTE) {
                $list[] = $ms;
                Cache::put(self::key($minute), $list, (self::WINDOW_MINUTES + 1) * 60);
            }
        } catch (Throwable) {
            // A busy cache never slows the match: this sample is lost.
        }
    }

    /** @return array{live: array{samples: int, p50_ms: int|null, p95_ms: int|null}, queue: int|null, reverb_connections: int|null} */
    public static function read(): array
    {
        $now = intdiv(GameClock::nowMs(), 60_000);
        $all = [];
        for ($m = $now - self::WINDOW_MINUTES + 1; $m <= $now; $m++) {
            array_push($all, ...Cache::get(self::key($m), []));
        }
        sort($all);

        return [
            'live' => ['samples' => count($all), 'p50_ms' => self::percentile($all, 50), 'p95_ms' => self::percentile($all, 95)],
            'queue' => self::queue(),
            'reverb_connections' => self::reverb(),
        ];
    }

    /** The p-th percentile of sorted values (nearest rank), or null with none. */
    public static function percentile(array $sorted, int $p): ?int
    {
        if (! $sorted) {
            return null;
        }
        $rank = max(1, (int) ceil($p * count($sorted) / 100));

        return (int) $sorted[$rank - 1];
    }

    private static function queue(): ?int
    {
        try {
            return Queue::size();
        } catch (Throwable) {
            return null;
        }
    }

    private static function reverb(): ?int
    {
        if (config('broadcasting.default') !== 'reverb') {
            return null;
        }
        try {
            $answer = Broadcast::connection('reverb')->getPusher()->get('/connections');
            $n = is_object($answer) ? ($answer->connections ?? null) : ($answer['connections'] ?? null);

            return is_numeric($n) ? (int) $n : null;
        } catch (Throwable) {
            return null;
        }
    }
}
