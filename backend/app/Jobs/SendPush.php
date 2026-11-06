<?php

namespace App\Jobs;

use App\Notify\Fcm;
use App\Notify\Push;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\DB;
use Minishlink\WebPush\Subscription;
use Minishlink\WebPush\WebPush;

/** One push to every browser [Sprint 36] and app [Sprint 19] of an account. A subscription its service says is gone is removed. */
class SendPush implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    public int $tries = 2;

    public function __construct(public int $userId, public array $payload) {}

    public function handle(): void
    {
        // [Sprint 19 B1] The app's devices by FCM; a token Firebase says is dead is removed.
        if (Fcm::configured()) {
            foreach (DB::table('push_subscriptions')->where('user_id', $this->userId)->where('channel', 'fcm')->pluck('endpoint') as $token) {
                if (Fcm::send($token, $this->payload) === 'gone') {
                    DB::table('push_subscriptions')->where('endpoint', $token)->delete();
                }
            }
        }
        if (! Push::configured()) {
            return;
        }
        $v = config('game.notifications.vapid');
        $push = new WebPush(['VAPID' => ['subject' => $v['subject'], 'publicKey' => $v['public'], 'privateKey' => $v['private']]], ['TTL' => 3600]);
        $subs = DB::table('push_subscriptions')->where('user_id', $this->userId)->where('channel', 'webpush')->get();
        foreach ($subs as $s) {
            $push->queueNotification(Subscription::create(['endpoint' => $s->endpoint, 'publicKey' => $s->p256dh, 'authToken' => $s->auth]),
                json_encode($this->payload, JSON_UNESCAPED_UNICODE));
        }
        foreach ($push->flush() as $report) {
            if ($report->isSubscriptionExpired()) {
                DB::table('push_subscriptions')->where('endpoint', $report->getEndpoint())->delete();
            }
        }
    }
}
