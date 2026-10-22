<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/** Messages read on one screen [Sprint 22]: the account's other screens mark them read too. */
class MessagesRead implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $userId, public array $ids, public int $unread) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("App.Models.User.{$this->userId}");
    }

    public function broadcastAs(): string
    {
        return 'messages-read';
    }

    public function broadcastWith(): array
    {
        return ['ids' => $this->ids, 'unread' => $this->unread];
    }
}
