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
        // يُعدّ في الذاكرة المؤقتة، فترى كل عملية عاملة الرقم نفسه
        $attempt = Cache::increment("mail-attempts:$orderId");
        // خدمة بريد تفشل أول مرتين للطلب 1003
        if ($orderId === 1003 && $attempt <= 2) {
            throw new RuntimeException('خدمة البريد غير متاحة');
        }
    }
}
