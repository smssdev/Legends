<?php

namespace App\Console\Commands;

use App\League\MatchReplay;
use Illuminate\Console\Command;

/**
 * [Sprint 43 C6, Hamza 2026-11-05] A match's replay lasts its round: once the next one has started, its kept scene goes
 * and its result, report and events stay (MatchReplay::expired). Hourly.
 */
class MatchesPruneReplays extends Command
{
    protected $signature = 'matches:prune-replays';

    protected $description = 'Delete the replays of matches whose round is over (their results stay)';

    public function handle(): int
    {
        $this->info('Deleted '.MatchReplay::prune().' replays.');

        return self::SUCCESS;
    }
}
