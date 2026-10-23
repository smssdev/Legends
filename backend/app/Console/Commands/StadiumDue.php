<?php

namespace App\Console\Commands;

use App\Stadium\Stadium;
use Illuminate\Console\Command;

/** Every minute: the stadium parts whose time has come, coach online or not [PLAN 2.9, Sprint 29]. */
class StadiumDue extends Command
{
    protected $signature = 'stadium:due';

    protected $description = 'Finish the stadium parts that are due';

    public function handle(): int
    {
        $n = Stadium::due();
        if ($n) {
            $this->line("أجزاء الملعب: {$n}");
        }

        return self::SUCCESS;
    }
}
