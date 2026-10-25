<?php

namespace App\Console\Commands;

use App\Staff\Specialists;
use Illuminate\Console\Command;

/** Every minute: staff whose contract ended unrenewed resign, and their coaches are told [X20]. */
class StaffDue extends Command
{
    protected $signature = 'staff:due';

    protected $description = 'Tell coaches whose staff contracts ended';

    public function handle(): int
    {
        $this->line('Resignations: '.Specialists::due());

        return self::SUCCESS;
    }
}
