<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * How many matches are live now. The update script waits for zero before it deploys [PLAN 2.12]:
 * no deploy while a match is being played.
 */
class MatchesLive extends Command
{
    protected $signature = 'matches:live';

    protected $description = 'Count the matches being played now';

    public function handle(): int
    {
        $this->line((string) DB::table('matches')->where('status', 'live')->count());

        return self::SUCCESS;
    }
}
