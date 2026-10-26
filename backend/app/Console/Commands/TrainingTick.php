<?php

namespace App\Console\Commands;

use App\Training\Training;
use Illuminate\Console\Command;

/** Every minute: the training sessions whose time has come, coach online or not [PLAN 2.8, Sprints 27 and 28]. */
class TrainingTick extends Command
{
    protected $signature = 'training:tick';

    protected $description = 'Run the training sessions that are due';

    public function handle(): int
    {
        $n = Training::due();
        if ($n) {
            $this->line("جلسات التدريب: {$n}");
        }

        return self::SUCCESS;
    }
}
