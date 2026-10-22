<?php

namespace App\Console\Commands;

use App\Support\ServerHealth;
use Illuminate\Console\Command;

/**
 * The health check [PLAN 2.19, Sprint 21 B2]: the home server's watchdog runs it every minute with --notify,
 * after starting any task that had stopped. --json gives the states to the watchdog; the exit code is 1
 * when a service is down.
 */
class ServerHealthCheck extends Command
{
    protected $signature = 'server:health {--notify : Alert the phones (ntfy) when a service goes down or comes back} {--json}';

    protected $description = 'Check that every always-on service of the server is alive';

    public function handle(): int
    {
        $checks = ServerHealth::check();
        if ($this->option('json')) {
            $this->line(json_encode($checks, JSON_UNESCAPED_UNICODE));
        } else {
            $this->table(['الخدمة', 'الحالة', ''], collect($checks)->map(fn ($c, $s) => [ServerHealth::NAMES[$s], $c['ok'] ? 'تعمل' : 'متوقفة', $c['detail']])->values()->all());
        }
        if ($this->option('notify')) {
            $lines = ServerHealth::alerts($checks);
            if ($lines && ! ServerHealth::notify($lines)) {
                $this->warn(config('game.monitoring.ntfy_topic') ? 'تعذر إرسال التنبيه.' : 'لا يوجد NTFY_TOPIC في .env: لم يُرسل تنبيه.');
            }
        }

        return collect($checks)->every(fn ($c) => $c['ok']) ? self::SUCCESS : self::FAILURE;
    }
}
