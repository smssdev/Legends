<?php

use App\Jobs\SalesReport;
use App\Jobs\SendOrderConfirmation;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schedule;

// تقرير المبيعات كل صباح في السادسة بتوقيت القاهرة
Schedule::job(new SalesReport)->dailyAt('06:00')->timezone('Africa/Cairo');

Artisan::command('shop:dispatch', function () {
    foreach ([1001, 1002, 1003, 1004, 1001] as $orderId) {
        $start = hrtime(true);
        DB::transaction(function () use ($orderId) {
            // ... the order is saved here ...
            // يُرسل إلى الطابور فقط إن ثُبّتت المعاملة
            SendOrderConfirmation::dispatch($orderId)->afterCommit();
        });
        $ms = number_format((hrtime(true) - $start) / 1e6, 1);
        $this->line("order $orderId: في الطابور خلال $ms ms");
    }
});
