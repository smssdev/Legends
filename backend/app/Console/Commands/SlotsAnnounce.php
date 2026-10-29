<?php

namespace App\Console\Commands;

use App\League\CoachSlots;
use Illuminate\Console\Command;

/** Every five minutes: a coach whose account just became old enough for a new slot is told [Sprint 24 B3]. */
class SlotsAnnounce extends Command
{
    protected $signature = 'slots:announce';

    protected $description = 'Tell coaches a new slot opened with their account age';

    public function handle(): int
    {
        $this->line('Slots announced: '.CoachSlots::announce());

        return self::SUCCESS;
    }
}
