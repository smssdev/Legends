<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

// broadcast at once; with ShouldBroadcast it would go through the queue
class OrderStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $orderId, public string $status) {}

    // the channel: everyone watching order 1001 listens here
    public function broadcastOn(): array
    {
        return [new Channel("orders.{$this->orderId}")];
    }

    // the event's name, as clients see it
    public function broadcastAs(): string
    {
        return 'status';
    }

    // exactly what clients receive: nothing more than they need
    public function broadcastWith(): array
    {
        return ['order' => $this->orderId, 'status' => $this->status];
    }
}
