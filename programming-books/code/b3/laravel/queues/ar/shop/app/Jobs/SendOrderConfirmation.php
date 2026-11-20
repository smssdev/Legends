<?php

namespace App\Jobs;

use App\Support\Mailer;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

// في الطابور: سينادي العامل handle() لاحقاً، في عملية أخرى
class SendOrderConfirmation implements ShouldBeUnique, ShouldQueue
{
    use Queueable;

    // حتى 3 محاولات، بانتظار ثانية ثم ثانيتين بينها
    public int $tries = 3;

    public array $backoff = [1, 2];

    public function __construct(public int $orderId) {}

    // مهمة واحدة لكل طلب: إرسال الطلب نفسه مرة أخرى وهو ينتظر لا يفعل شيئاً
    public function uniqueId(): string
    {
        return "order-{$this->orderId}";
    }

    // العمل نفسه: يُستدعى مرة لكل محاولة
    public function handle(Mailer $mailer): void
    {
        echo "  إرسال تأكيد الطلب {$this->orderId} (المحاولة {$this->attempts()})\n";
        // المهمة تحمل رقم الطلب؛ والبيانات تُقرأ حين تعمل
        $email = DB::table('orders')->where('id', $this->orderId)->value('email');
        if (! str_contains($email, '@')) {
            // عنوان لا يمكن أن ينجح أبداً: افشل الآن، بلا المحاولات الباقية
            $this->fail("عنوان غير صالح: $email");

            return;
        }
        $mailer->send($this->orderId, $email);
    }

    // يُستدعى مرة، بعد آخر محاولة: أخبر أحداً
    public function failed(?Throwable $error): void
    {
        Log::error("توقفنا عن تأكيد الطلب {$this->orderId}", ['reason' => $error?->getMessage()]);
    }
}
