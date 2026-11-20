<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SalesReport implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        echo '  تقرير المبيعات عن '.now('Africa/Cairo')->subDay()->toDateString()."\n";
    }
}
