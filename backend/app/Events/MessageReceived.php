<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/** A new message [Sprint 22 B1]: on its account's own channel, with the unread count for the badge. */
class MessageReceived implements ShouldBroadcastNow, ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(public int $userId, public array $message, public int $unread) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("App.Models.User.{$this->userId}");
    }

    public function broadcastAs(): string
    {
        return 'message';
    }

    public function broadcastWith(): array
    {
        return ['message' => $this->message, 'unread' => $this->unread];
    }
}
