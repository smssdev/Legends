<?php

namespace App\Console\Commands;

use App\Auth\GuestAccounts;
use Illuminate\Console\Command;

/** [Sprint 50 M5] Deletes the guests' accounts never kept within game.account.guest_days. */
class GuestsPrune extends Command
{
    protected $signature = 'guests:prune';

    protected $description = 'Delete guest accounts that were never kept';

    public function handle(): int
    {
        $this->info('Deleted '.GuestAccounts::prune().' guest accounts.');

        return self::SUCCESS;
    }
}
