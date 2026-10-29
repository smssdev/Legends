<?php

namespace App\Events;

use App\League\LiveDegrade;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * A live league minute [PLAN 2.12, 2.13]: on the match's private channel, for the league's members only.
 * It carries the minute, the score, the scene and the events with both sides' tactics taken out
 * (Simulator::redact); the frames and the players' numbers are fetched from GET /matches/{id}/live, so a
 * message stays small. Hidden tactics never travel here.
 *
 * The protocol's layers [Sprint 21 E8.3]: L0 is the match once (GET /matches/{id}), L1 this MatchMinute, every
 * minute, with match_time and server_ts, and L3 the report and the replay after the final whistle. The payload is
 * built once, redacted for nobody, and the broadcaster sends the same bytes to every member on the channel.
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
            'at' => $this->tick['at'] ?? null,
            // [E8.3] Where the minute starts on the match's own clock (ms) and when the server made it (ms).
            'match_time' => $this->tick['match_time'] ?? self::matchTime($this->tick['tick']),
            'server_ts' => $this->tick['server_ts'] ?? null,
            'moment' => $this->tick['moment'], 'finished' => $this->tick['finished'],
            'events' => $this->tick['events'],
            // The commentator's line for this minute, drawn on the server [Sprint 35].
            // [E8.7] Under load the voice is the second thing given up (App\League\LiveDegrade).
            'voice' => LiveDegrade::voice() ? ($this->tick['voice'] ?? null) : null,
        ];
    }

    /**
     * The minute's start on the match's own clock, in ms: one minute of football for every Tick before it,
     * stoppage time included, so it only grows (the displayed minute repeats: 45+2 then 46). Clients key
     * their RenderFrames to it, not to when the message arrived.
     */
    public static function matchTime(int $tick): int
    {
        return max(0, $tick - 1) * 60_000;
    }
}
