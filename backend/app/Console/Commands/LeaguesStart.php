<?php

namespace App\Console\Commands;

use App\League\LeagueStarter;
use Illuminate\Console\Command;

/** Every minute: start the leagues whose start time has come, and lock their settings [PLAN 2.1, 2.3]. */
class LeaguesStart extends Command
{
    protected $signature = 'leagues:start';

    protected $description = 'Start the leagues whose time has come';

    public function handle(): int
    {
        $n = LeagueStarter::due();
        if ($n > 0) {
            $this->line("بدأ {$n} دوري.");
        }

        return self::SUCCESS;
    }
}
