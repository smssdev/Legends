<?php

namespace App\Jobs;

use App\Support\Mailer;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

// queued: the worker will call handle() later, in another process
class SendOrderConfirmation implements ShouldBeUnique, ShouldQueue
{
    use Queueable;

    // up to 3 attempts, waiting 1, then 2 seconds between them
    public int $tries = 3;

    public array $backoff = [1, 2];

    public function __construct(public int $orderId) {}

    // one job per order: dispatching the same order again while it waits does nothing
    public function uniqueId(): string
    {
        return "order-{$this->orderId}";
    }

    // the work itself: called once per attempt
    public function handle(Mailer $mailer): void
    {
        echo "  sending the confirmation for order {$this->orderId} (attempt {$this->attempts()})\n";
        // the job carries the order id; the data is read when it runs
        $email = DB::table('orders')->where('id', $this->orderId)->value('email');
        if (! str_contains($email, '@')) {
            // an address that can never work: fail now, without the remaining attempts
            $this->fail("invalid address: $email");

            return;
        }
        $mailer->send($this->orderId, $email);
    }

    // called once, after the last attempt: tell someone
    public function failed(?Throwable $error): void
    {
        Log::error("gave up on the confirmation for order {$this->orderId}", ['reason' => $error?->getMessage()]);
    }
}
