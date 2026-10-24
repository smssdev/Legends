<?php

namespace App\Console\Commands;

use App\Market\Buyer;
use App\Market\Pool;
use App\Market\Transfers;
use Illuminate\Console\Command;

/** Every minute: a transfer window that has opened renews its league's market pool, and old offers expire [PLAN 2.7]. */
class MarketRenew extends Command
{
    protected $signature = 'market:renew';

    protected $description = 'Renew the market pool of the windows that have opened';

    public function handle(): int
    {
        $n = Pool::due();
        // Offers between coaches past their time, and the listed players whose buyer has come [X6].
        Transfers::expire();
        Buyer::due();
        if ($n) {
            $this->line("تجددت مجموعة السوق في {$n} نافذة.");
        }

        return self::SUCCESS;
    }
}
