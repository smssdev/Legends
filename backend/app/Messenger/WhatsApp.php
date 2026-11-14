<?php

namespace App\Messenger;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * [Sprint 67] WhatsApp by Meta's official Cloud API, used only where it is free: answering a coach who wrote to the
 * bot, and writing to him within 24 hours of his last message (the customer-service window). Never a template, never
 * a message to someone who did not write: those are the paid ones.
 */
class WhatsApp
{
    public static function configured(): bool
    {
        return (bool) config('services.whatsapp.token') && (bool) config('services.whatsapp.phone_id')
            && (bool) config('services.whatsapp.app_secret') && (bool) config('services.whatsapp.verify');
    }

    public static function number(): ?string
    {
        $n = preg_replace('/\D/', '', (string) config('services.whatsapp.number'));

        return $n !== '' ? $n : null;
    }

    /** The signature Meta puts on every webhook call (X-Hub-Signature-256), with the app's secret. */
    public static function signed(string $body, ?string $header): bool
    {
        $secret = (string) config('services.whatsapp.app_secret');

        return $secret !== '' && $header !== null && hash_equals('sha256='.hash_hmac('sha256', $body, $secret), $header);
    }

    /** A text message, with up to three reply buttons ([label, command]) under it. Returns 'sent' or 'failed'. */
    public static function send(string $to, string $text, array $buttons = []): string
    {
        // A link button has no place among WhatsApp's reply buttons: its link goes in the text.
        foreach ($buttons as $b) {
            if (str_starts_with($b[1], 'url:')) {
                $text .= "\n".substr($b[1], 4);
            }
        }
        $buttons = array_values(array_filter($buttons, fn ($b) => ! str_starts_with($b[1], 'url:')));
        $text = Messenger::clip($text);
        $body = $buttons
            ? ['messaging_product' => 'whatsapp', 'to' => $to, 'type' => 'interactive', 'interactive' => ['type' => 'button',
                'body' => ['text' => $text],
                'action' => ['buttons' => array_map(fn ($b) => ['type' => 'reply', 'reply' => ['id' => $b[1], 'title' => mb_substr($b[0], 0, 20)]], array_slice($buttons, 0, 3))]]]
            : ['messaging_product' => 'whatsapp', 'to' => $to, 'type' => 'text', 'text' => ['body' => $text, 'preview_url' => false]];
        try {
            $r = Http::timeout((int) config('services.whatsapp.timeout'))->acceptJson()->withToken((string) config('services.whatsapp.token'))
                ->post(rtrim((string) config('services.whatsapp.url'), '/').'/'.config('services.whatsapp.phone_id').'/messages', $body);

            return $r->successful() ? 'sent' : 'failed';
        } catch (Throwable) {
            return 'failed';
        }
    }
}
