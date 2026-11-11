<?php

namespace App\Support;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * The home server's health [PLAN 2.19, Sprint 21 B2]: is every always-on service alive? The web answers
 * /api/v1/health, Reverb takes a connection on its port, the match runner holds its claim (renewed every
 * step), and the queue worker and the scheduler leave a sign of life in the cache. When one goes down or
 * comes back, an alert goes to the phones by ntfy (once, then again every half hour while it stays down).
 */
class ServerHealth
{
    public const NAMES = ['web' => 'الموقع', 'live' => 'البث المباشر', 'matches' => 'مشغّل المباريات',
        'queue' => 'الطابور', 'scheduler' => 'المجدول', 'database' => 'قاعدة البيانات', 'disk' => 'مساحة القرص'];

    /** Called by the queue worker on every loop and the scheduler every minute. Writes at most every 15 s. */
    public static function beat(string $service): void
    {
        static $last = [];
        $now = GameClock::nowMs();
        if (($last[$service] ?? 0) > $now - 15_000) {
            return;
        }
        $last[$service] = $now;
        try {
            Cache::put("heartbeat:{$service}", $now, 3600);
        } catch (Throwable) {
            // A busy cache file never stops the worker: the next beat writes it.
        }
    }

    /** @return array<string, array{ok: bool, detail: string}> */
    public static function check(): array
    {
        $stale = config('game.monitoring.stale');

        return [
            'web' => self::web(),
            'live' => self::live(),
            'matches' => Cache::has('matches-runner') ? self::up('يلعب') : self::down('لا يوجد مشغّل يعمل'),
            'queue' => self::fresh('queue', $stale['queue']),
            'scheduler' => self::fresh('scheduler', $stale['scheduler']),
            'database' => self::database(),
            'disk' => self::disk(),
        ];
    }

    /**
     * The alerts this check calls for: a service that went down, one still down for another half hour, and
     * one that came back. Remembers what it said in the cache.
     *
     * @return list<string>
     */
    public static function alerts(array $checks): array
    {
        $down = Cache::get('health:down', []);
        $now = GameClock::nowMs();
        $remind = (int) config('game.monitoring.remind_minutes') * 60_000;
        $lines = [];
        foreach ($checks as $service => $c) {
            $name = self::NAMES[$service];
            if (! $c['ok'] && ! isset($down[$service])) {
                $down[$service] = ['since' => $now, 'told' => $now];
                $lines[] = "🔴 توقف {$name}: {$c['detail']}";
            } elseif (! $c['ok'] && $down[$service]['told'] <= $now - $remind) {
                $down[$service]['told'] = $now;
                $minutes = intdiv($now - $down[$service]['since'], 60_000);
                $lines[] = "🔴 {$name} ما زال متوقفاً منذ {$minutes} دقيقة: {$c['detail']}";
            } elseif ($c['ok'] && isset($down[$service])) {
                $minutes = intdiv($now - $down[$service]['since'], 60_000);
                unset($down[$service]);
                $lines[] = "🟢 عاد {$name} للعمل بعد {$minutes} دقيقة.";
            }
        }
        Cache::forever('health:down', $down);

        return $lines;
    }

    /** Send the alert to every phone subscribed to the topic. False when there is no topic or it failed. */
    public static function notify(array $lines): bool
    {
        $topic = config('game.monitoring.ntfy_topic');
        if (! $topic || ! $lines) {
            return false;
        }
        $down = collect($lines)->contains(fn ($l) => str_starts_with($l, '🔴'));
        try {
            return Http::timeout(10)->withHeaders([
                // Headers are ASCII: the Arabic text goes in the body.
                'Title' => $down ? 'Legends: service down' : 'Legends: back to normal',
                'Priority' => $down ? 'urgent' : 'default',
                'Tags' => $down ? 'rotating_light' : 'white_check_mark',
            ])->withBody(implode("\n", $lines), 'text/plain; charset=utf-8')
                ->post(rtrim(config('game.monitoring.ntfy_server'), '/').'/'.$topic)->successful();
        } catch (Throwable) {
            return false;
        }
    }

    private static function web(): array
    {
        try {
            $r = Http::timeout(5)->acceptJson()->get(rtrim(config('game.monitoring.web_url'), '/').'/api/v1/health');

            return $r->successful() && $r->json('status') === 'ok' ? self::up('يستجيب') : self::down("يرد بالرمز {$r->status()}");
        } catch (Throwable) {
            return self::down('لا يستجيب');
        }
    }

    private static function live(): array
    {
        // [Sprint 52] Where the game publishes to Reverb (its own service on our server, REVERB_HOST), else this machine.
        $host = (string) (config('broadcasting.connections.reverb.options.host') ?: config('reverb.servers.reverb.host'));
        $host = in_array($host, ['', '0.0.0.0'], true) ? '127.0.0.1' : $host;
        $port = (int) (config('broadcasting.connections.reverb.options.port') ?: config('reverb.servers.reverb.port'));
        $socket = @fsockopen($host, $port, $errno, $error, 3);
        if ($socket) {
            fclose($socket);

            return self::up("يستقبل على {$port}");
        }

        return self::down("لا يستقبل على {$port}");
    }

    private static function fresh(string $service, int $seconds): array
    {
        $at = Cache::get("heartbeat:{$service}");
        if (! $at) {
            return self::down('لم يُرَ يعمل');
        }
        $ago = intdiv(GameClock::nowMs() - (int) $at, 1000);

        return $ago <= $seconds ? self::up("قبل {$ago} ثانية") : self::down("آخر علامة قبل {$ago} ثانية");
    }

    private static function database(): array
    {
        try {
            DB::select('select 1');

            return self::up('تقرأ');
        } catch (Throwable $e) {
            return self::down('لا تُقرأ');
        }
    }

    private static function disk(): array
    {
        $free = @disk_free_space(database_path());
        if ($free === false) {
            return self::up('غير معروفة');
        }
        $mb = intdiv((int) $free, 1024 * 1024);

        return $mb >= (int) config('game.monitoring.min_free_mb') ? self::up("{$mb} ميجا فارغة") : self::down("بقي {$mb} ميجا فقط");
    }

    private static function up(string $detail): array
    {
        return ['ok' => true, 'detail' => $detail];
    }

    private static function down(string $detail): array
    {
        return ['ok' => false, 'detail' => $detail];
    }
}
