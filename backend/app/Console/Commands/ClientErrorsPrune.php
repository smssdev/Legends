<?php

namespace App\Console\Commands;

use App\Support\ClientErrors;
use App\Support\ClientFrames;
use Illuminate\Console\Command;

/** [Sprint 66 B1] Delete the devices' errors not seen for 30 days (daily). */
class ClientErrorsPrune extends Command
{
    protected $signature = 'client-errors:prune';

    protected $description = 'Delete the client errors not seen for 30 days';

    public function handle(): int
    {
        $this->info('Client errors: '.ClientErrors::prune().' old rows deleted.');
        // [Sprint 74 P2] And the phones' frame counts, on the same 30 days.
        $this->info('Client frames: '.ClientFrames::prune().' old rows deleted.');

        return self::SUCCESS;
    }
}
