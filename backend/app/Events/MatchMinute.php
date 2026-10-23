<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * A live league minute [PLAN 2.12, 2.13]: on the match's private channel, for the league's members only.
 * It carries the minute, the score, the scene and the events with both sides' tactics taken out
 * (Simulator::redact); the frames and the players' numbers are fetched from GET /matches/{id}/live, so a
 * message stays small. Hidden tactics never travel here.
 */
class MatchMinute implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public object $fixture, public int $matchId, public array $tick) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("match.{$this->matchId}");
    }

    public function broadcastAs(): string
    {
        return 'minute';
    }

    public function broadcastWith(): array
    {
        return [
            'match_id' => $this->matchId,
            'tick' => $this->tick['tick'], 'minute' => $this->tick['minute'], 'score' => $this->tick['score'],
            'at' => $this->tick['at'] ?? null, 'moment' => $this->tick['moment'], 'finished' => $this->tick['finished'],
            'events' => $this->tick['events'],
            // The commentator's line for this minute, drawn on the server [Sprint 35].
            'voice' => $this->tick['voice'] ?? null,
        ];
    }
}
