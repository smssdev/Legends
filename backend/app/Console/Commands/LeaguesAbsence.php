<?php

namespace App\Console\Commands;

use App\League\Presence;
use Illuminate\Console\Command;

/** Every minute: the absence warning at 48 hours, and coaches away for 3 days leave [PLAN 2.2]. */
class LeaguesAbsence extends Command
{
    protected $signature = 'leagues:absence';

    protected $description = 'Warn quiet coaches and send away those gone too long';

    public function handle(): int
    {
        [$warned, $gone] = Presence::check();
        if ($warned + $gone > 0) {
            $this->line("تنبيه: {$warned} · طرد بالغياب: {$gone}");
        }

        return self::SUCCESS;
    }
}
