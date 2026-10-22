<?php

namespace App\Console\Commands;

use App\League\MatchPrep;
use Illuminate\Console\Command;

/** Every minute: the referee 30 minutes before a match, the lock 5 minutes before [PLAN 2.13]. */
class MatchesPrepare extends Command
{
    protected $signature = 'matches:prepare';

    protected $description = 'Draw referees and lock the sides before their matches';

    public function handle(): int
    {
        [$refs, $locks] = MatchPrep::run();
        if ($refs + $locks > 0) {
            $this->line("حكام: {$refs} · قفل: {$locks}");
        }

        return self::SUCCESS;
    }
}
