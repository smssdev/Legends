<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/** [Sprint 50 M14] A side called its timeout: play waits until `until` (ms) on every screen of the match. */
class MatchTimeout implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $matchId, public array $timeout) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("match.{$this->matchId}");
    }

    public function broadcastAs(): string
    {
        return 'timeout';
    }

    public function broadcastWith(): array
    {
        return ['match_id' => $this->matchId] + $this->timeout;
    }
}
