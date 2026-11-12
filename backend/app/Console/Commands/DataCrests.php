<?php

namespace App\Console\Commands;

use App\Data\Crests;
use Illuminate\Console\Command;

/** [Sprint 58 B2] Writes the clubs' crests as static files (App\Data\Crests), on every start of the web server. */
class DataCrests extends Command
{
    protected $signature = 'data:crests';

    protected $description = "Write the clubs' crests to public/crests with a manifest (Sprint 58 B2)";

    public function handle(): int
    {
        $n = Crests::write();
        $this->info("{$n} crests written to public/crests.");

        return self::SUCCESS;
    }
}
