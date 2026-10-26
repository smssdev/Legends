<?php

namespace App\Console\Commands;

use App\Auth\AccountHolidays;
use Illuminate\Console\Command;

/** Every day [UP13]: warn the accounts unused for 12 days, delete those unused for 14 (never one on holiday). */
class AccountsInactive extends Command
{
    protected $signature = 'accounts:inactive';

    protected $description = 'Warn, then delete, the accounts unused for game.inactivity days';

    public function handle(): int
    {
        [$warned, $deleted] = AccountHolidays::sweep();
        $this->info("warned {$warned}, deleted {$deleted}");

        return self::SUCCESS;
    }
}
