<?php

namespace App\Jobs;

use App\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

// the job carries only the id, and reads the rest when it runs
class SendOrderEmail implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    public array $backoff = [5, 30, 120];

    public function __construct(public int $orderId) {}

    public function handle(): void
    {
        $order = Order::with('user:id,email')->findOrFail($this->orderId);
        Log::info('email sent', ['to' => $order->user->email, 'order_id' => $order->id]);
    }
}
