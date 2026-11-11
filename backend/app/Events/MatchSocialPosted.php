<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * [Sprint 53 B3] A reaction or a side-chat line in a live league match [X24], on the match's channel (its league's
 * members only) as soon as it is posted: the screens no longer wait for their next poll to show it. The same item the
 * poll gives (MatchSocial::recent), so a screen that misses the event still gets it there.
 */
class MatchSocialPosted implements ShouldBroadcastNow
{
    use Dispatchable;

    /** @param  'reactions'|'chat'  $list */
    public function __construct(public int $matchId, public string $list, public array $item) {}

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("match.{$this->matchId}");
    }

    public function broadcastAs(): string
    {
        return $this->list === 'chat' ? 'chat' : 'reaction';
    }

    public function broadcastWith(): array
    {
        return ['match_id' => $this->matchId, 'item' => $this->item];
    }
}
