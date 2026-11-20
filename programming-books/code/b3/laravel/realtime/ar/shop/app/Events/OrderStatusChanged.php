<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

// يُبث في الحال؛ ومع ShouldBroadcast يمر عبر الطابور
class OrderStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $orderId, public string $status) {}

    // القناة: كل من يتابع الطلب 1001 يستمع هنا
    public function broadcastOn(): array
    {
        return [new Channel("orders.{$this->orderId}")];
    }

    // اسم الحدث، كما يراه العملاء
    public function broadcastAs(): string
    {
        return 'status';
    }

    // بالضبط ما يستقبله العملاء: لا أكثر مما يحتاجون
    public function broadcastWith(): array
    {
        return ['order' => $this->orderId, 'status' => $this->status];
    }
}
