<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/** [X66] A line or reaction in a live draw's chat (or its deletion), on the draw's channel for everyone watching. */
class DrawChatSent implements ShouldBroadcastNow, ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(public int $leagueId, public array $message) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("draw.{$this->leagueId}");
    }

    public function broadcastAs(): string
    {
        return 'draw-chat';
    }

    public function broadcastWith(): array
    {
        return ['message' => $this->message];
    }
}
