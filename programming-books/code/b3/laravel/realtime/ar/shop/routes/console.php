<?php

use App\Events\OrderStatusChanged;
use Illuminate\Support\Facades\Artisan;

Artisan::command('shop:status {order} {status}', function (int $order, string $status) {
    // ... the order's status is saved in the database here ...
    OrderStatusChanged::dispatch($order, $status);
    $this->line(strtr('الطلب {order} صار {status}', ['{order}' => $order, '{status}' => $status]));
});
