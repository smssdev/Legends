<?php

namespace App\Support;

use Illuminate\Support\Facades\Cache;
use RuntimeException;

// A stand-in for a real mail service, with its bad days.
class Mailer
{
    public function send(int $orderId, string $email): void
    {
        usleep(300_000);
        // counted in the cache, so every worker process sees the same number
        $attempt = Cache::increment("mail-attempts:$orderId");
        // a mail service that fails the first two times for order 1003
        if ($orderId === 1003 && $attempt <= 2) {
            throw new RuntimeException('mail service unavailable');
        }
    }
}
