<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * The test broadcast [Sprint 9 B3]: proves Reverb reaches the browser. On the public
 * "system" channel because it carries nothing private; match channels are private
 * to the league's members.
 */
class ServerPing implements ShouldBroadcastNow
{
    use Dispatchable;

    public const CHANNEL = 'system';

    public const NAME = 'ping';

    public function __construct(public string $at) {}

    public function broadcastOn(): Channel
    {
        return new Channel(self::CHANNEL);
    }

    public function broadcastAs(): string
    {
        return self::NAME;
    }

    public function broadcastWith(): array
    {
        return ['at' => $this->at, 'message' => 'البث يعمل'];
    }
}
