<?php

namespace App\Support;

use Illuminate\Broadcasting\BroadcastException;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * [Sprint 53] How the game sends a live event (a match's minute, a chat line, a message): the events go out at once
 * (ShouldBroadcastNow), so with Reverb down for a moment (a restart, a deploy) the send fails. That must never stop the
 * thing it reports: the match runner went on failing every minute until Reverb was back, so every live match stood
 * still, and a chat line already saved answered with an error. The screens catch up from the API when the channel
 * returns (the match's poll, the inbox's count), so here the failure is written to the log, once a minute at most.
 */
final class LiveEvents
{
    public static function send(object $event): void
    {
        // An event that waits for the transaction (a message is seen only once it is saved) is sent from here after
        // the commit, so its failure is caught too: Laravel would send it later, outside this try.
        if ($event instanceof ShouldDispatchAfterCommit && DB::transactionLevel() > 0) {
            DB::afterCommit(fn () => self::now($event));

            return;
        }
        self::now($event);
    }

    private static function now(object $event): void
    {
        try {
            event($event);
        } catch (BroadcastException $e) {
            if (Cache::add('live-events:failing', 1, 60)) {
                Log::warning('Live events not sent (Reverb unreachable): '.$e->getMessage());
            }
        }
    }
}
