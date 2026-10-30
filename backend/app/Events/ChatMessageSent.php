<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/** [Sprint 29] A chat group's message, new or deleted, on the group's channel: every member's screen shows it at once. */
class ChatMessageSent implements ShouldBroadcastNow, ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(public int $groupId, public array $message) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("chat.{$this->groupId}");
    }

    public function broadcastAs(): string
    {
        return 'chat';
    }

    public function broadcastWith(): array
    {
        return ['message' => $this->message];
    }
}
