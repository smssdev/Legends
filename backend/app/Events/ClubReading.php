<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/** The assistant's live reading [ENGINE 8.2]: on the club's own channel, for its coach only. */
class ClubReading implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $clubId, public int $matchId, public array $reading) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("club.{$this->clubId}");
    }

    public function broadcastAs(): string
    {
        return 'reading';
    }

    public function broadcastWith(): array
    {
        return ['match_id' => $this->matchId] + array_intersect_key($this->reading, array_flip(['tick', 'minute', 'kind', 'text']));
    }
}
