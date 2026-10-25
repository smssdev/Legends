<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;

/**
 * Whether the emails really leave the server, and sending one without breaking the request around it [X8].
 * Render's free plan blocks SMTP, so there the emails go through Brevo or Resend over HTTPS (App\Mail\ApiTransport).
 */
class Mailer
{
    /** log and array keep the emails on the server: nobody receives them. */
    public static function live(): bool
    {
        return ! in_array(config('mail.default'), ['log', 'array'], true);
    }

    public static function name(): string
    {
        return (string) config('mail.default');
    }

    /** The last failure's text in this request, for the developers' own diagnosis. */
    public static ?string $lastError = null;

    /** Runs the send; a failure is logged with its reason and answered false, never thrown. */
    public static function attempt(callable $send, string $what): bool
    {
        try {
            $send();

            return true;
        } catch (\Throwable $e) {
            self::$lastError = $e->getMessage();
            Log::error("Email not sent ({$what}) through ".self::name().': '.$e->getMessage());

            return false;
        }
    }

    /**
     * What the server's email settings look like, and what to fix, in Arabic [X8]: for the admin panel's test (Render's
     * free plan has no shell for mail:check). Never shows a key, only whether it is there and its kind.
     */
    public static function setup(): array
    {
        $mailer = self::name();
        $key = (string) (config("mail.mailers.{$mailer}.key") ?? '');
        $problems = [];
        if (! self::live()) {
            $problems[] = 'البريد يُكتب في السجل ولا يُرسل: لا BREVO_API_KEY ولا RESEND_API_KEY ولا GMAIL في Environment، أو لم يُعد النشر بعد إضافتها (Manual Deploy).';
        }
        if ($mailer === 'brevo' && str_starts_with($key, 'xsmtpsib-')) {
            $problems[] = 'هذا مفتاح SMTP من Brevo. المطلوب مفتاح API: من SMTP & API ← تبويب API Keys ← Generate a new API key (يبدأ بـ xkeysib-).';
        }
        if (self::live() && ! filter_var((string) config('mail.from.address'), FILTER_VALIDATE_EMAIL)) {
            $problems[] = 'MAIL_FROM_ADDRESS فارغ أو غير صحيح: ضع البريد المؤكد كمرسل في Brevo.';
        }
        if (in_array($mailer, ['smtp'], true) && config('mail.mailers.smtp.host') === 'smtp.gmail.com' && getenv('RENDER')) {
            $problems[] = 'Render المجاني يمنع منافذ SMTP، فـ Gmail لا يعمل هنا. ضع BREVO_API_KEY.';
        }

        return ['mailer' => $mailer, 'from' => (string) config('mail.from.address'), 'key' => $key === '' ? 'none' : (str_starts_with($key, 'xkeysib-') ? 'api' : (str_starts_with($key, 'xsmtpsib-') ? 'smtp' : 'other')), 'problems' => $problems];
    }

    /** The reason an email was refused, and its fix in Arabic, from the service's own answer. */
    public static function explain(string $error): string
    {
        $e = strtolower($error);

        return match (true) {
            str_contains($e, 'unrecognised ip') || str_contains($e, 'unrecognized ip') || str_contains($e, 'authorised_ips') => 'Brevo يرفض عنوان خادمنا (Render يغيّر عناوينه). الحل: في Brevo ← Settings ← Security ← Authorised IPs ← عطّل حظر العناوين (Deactivate blocking).',
            str_contains($e, 'key not found') || str_contains($e, 'api-key') || str_contains($e, '(401)') => 'المفتاح مرفوض: تأكد أنه API key من Brevo (يبدأ بـ xkeysib-) ونُسخ كاملاً بلا مسافات، ثم Manual Deploy.',
            str_contains($e, 'sender') => 'المرسل غير مؤكد في Brevo: Senders, Domains & Dedicated IPs ← Senders ← أكّد البريد نفسه الموجود في MAIL_FROM_ADDRESS.',
            str_contains($e, 'not yet activated') || str_contains($e, 'validation') || str_contains($e, 'permission_denied') => 'حساب Brevo لم يُفعَّل للإرسال بعد: أكمل بيانات الحساب في Brevo، وقد يراجعونه خلال ساعات.',
            str_contains($e, 'could not be established') || str_contains($e, 'connection') || str_contains($e, 'timed out') => 'تعذر الاتصال بخدمة البريد: على Render المجاني استخدم BREVO_API_KEY لا Gmail.',
            default => 'راجع نص الخطأ أعلاه.',
        };
    }
}
