<?php

namespace App\Console\Commands;

use App\Market\Scout;
use Illuminate\Console\Command;

/** Every minute: the scouts' reports whose time has come, coach online or not [docs/features/scout.md]. */
class ScoutDue extends Command
{
    protected $signature = 'scout:due';

    protected $description = 'Deliver the scout reports that are due';

    public function handle(): int
    {
        $n = Scout::due();
        if ($n) {
            $this->line("تقارير الكشاف: {$n}");
        }

        return self::SUCCESS;
    }
}
