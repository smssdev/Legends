<?php

namespace App\Console\Commands;

use App\Season\SeasonEnd;
use Illuminate\Console\Command;

/** Every minute: the seasons whose last match is in end, and start again or end the league [PLAN 2.11, Sprint 33]. */
class SeasonsClose extends Command
{
    protected $signature = 'seasons:close';

    protected $description = 'Close the seasons whose last match is in';

    public function handle(): int
    {
        $n = SeasonEnd::due();
        if ($n) {
            $this->line("مواسم انتهت: {$n}");
        }

        return self::SUCCESS;
    }
}
