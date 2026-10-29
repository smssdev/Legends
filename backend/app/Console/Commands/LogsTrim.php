<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

/**
 * Log rotation [Sprint 21 E8.7]: the game's logs (storage/logs/*.log: the app, the queue, the scheduler, the match
 * runner, Reverb) grow while the container runs. Each one over max_mb is moved to NAME.log.1 (the one before goes)
 * and starts again empty. The writers append (>>), so they go on writing at the new end without a restart.
 */
class LogsTrim extends Command
{
    protected $signature = 'logs:trim {--dir= : The folder (default storage/logs)}';

    protected $description = 'Rotate the game\'s log files that grew over the size limit';

    public function handle(): int
    {
        $max = (int) config('game.logs.max_mb') * 1024 * 1024;
        $dir = $this->option('dir') ?: storage_path('logs');
        foreach (glob(rtrim($dir, '/').'/*.log') ?: [] as $file) {
            clearstatcache(true, $file);
            if (filesize($file) <= $max) {
                continue;
            }
            copy($file, "{$file}.1");
            // Emptied in place, not replaced: a process holding it open keeps writing to this same file.
            $h = fopen($file, 'r+');
            ftruncate($h, 0);
            fclose($h);
            $this->line('Rotated '.basename($file));
        }

        return self::SUCCESS;
    }
}
