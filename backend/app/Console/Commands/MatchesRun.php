<?php

namespace App\Console\Commands;

use App\League\MatchRunner;
use Illuminate\Console\Command;
use Illuminate\Support\Str;
use Throwable;

/**
 * The live runner [PLAN 2.12]: always on (a Windows task on the home server), it plays every due minute of
 * every live match, starts matches at their time and publishes the instant ones. Stopping it is safe: a
 * match resumes from its last saved state when it comes back. --once runs a single step (tests, cron).
 */
class MatchesRun extends Command
{
    protected $signature = 'matches:run {--once : One step and exit}';

    protected $description = 'Play the league matches live';

    private bool $stop = false;

    public function handle(): int
    {
        if (function_exists('pcntl_signal')) {
            pcntl_async_signals(true);
            pcntl_signal(SIGTERM, fn () => $this->stop = true);
            pcntl_signal(SIGINT, fn () => $this->stop = true);
        }
        $token = Str::random(16);
        $waiting = false;
        do {
            if (! MatchRunner::claim($token)) {
                if ($this->option('once')) {
                    $this->warn('Another runner is playing the matches.');

                    return self::FAILURE;
                }
                if (! $waiting) {
                    $this->warn('Another runner is playing the matches; this one waits.');
                    $waiting = true;
                }
                sleep(2);

                continue;
            }
            $waiting = false;
            try {
                [$started, $minutes, $published] = MatchRunner::step();
                if ($started + $published > 0) {
                    $this->line("بدأت: {$started} · دقائق: {$minutes} · نُشرت: {$published}");
                }
            } catch (Throwable $e) {
                // One bad step (a busy database, a broken match) must not stop every other match: log it and go on.
                report($e);
                $this->error($e->getMessage());
            }
            if ($this->option('once')) {
                break;
            }
            usleep((int) config('game.matches.runner_sleep_ms') * 1000);
        } while (! $this->stop);
        MatchRunner::release($token);

        return self::SUCCESS;
    }
}
