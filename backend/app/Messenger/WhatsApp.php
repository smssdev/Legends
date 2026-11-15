<?php

namespace App\Messenger;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * [Sprint 67] WhatsApp by Meta's official Cloud API, used only where it is free: answering a coach who wrote to the
 * bot, and writing to him within 24 hours of his last message (the customer-service window). Never a template, never
 * a message to someone who did not write: those are the paid ones.
 *
 * [Sprint 70] Every button Telegram shows works here too: up to three are reply buttons, more are one list (up to ten
 * rows), and a lone link is a link button. A text longer than an interactive message takes (1024) goes first on its
 * own, then the buttons under a short line. The coach's message is marked read, with «typing…» while the answer is made.
 */
class WhatsApp
{
    /** Meta's limits for the interactive messages. */
    private const BODY_MAX = 1024;

    private const ROWS_MAX = 10;

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

    /**
     * A text message, with buttons ([label, command] or [label, 'url:https://…']) under it. Returns 'sent', 'closed'
     * when Meta says the free window is shut (he has not written for 24 hours), or 'failed'.
     */
    public static function send(string $to, string $text, array $buttons = []): string
    {
        $links = array_values(array_filter($buttons, fn ($b) => str_starts_with($b[1], 'url:')));
        $replies = array_values(array_filter($buttons, fn ($b) => ! str_starts_with($b[1], 'url:')));
        $ar = (bool) preg_match('/\p{Arabic}/u', $text);
        // A lone link with nothing else to tap is a link button; any other link goes in the text.
        $cta = ! $replies && count($links) === 1 ? $links[0] : null;
        foreach ($cta ? [] : $links as $b) {
            $text .= "\n".substr($b[1], 4);
        }
        $text = Messenger::clip($text);
        if (! $replies && ! $cta) {
            return self::post(['type' => 'text', 'text' => ['body' => $text, 'preview_url' => false]], $to);
        }
        // Too long for an interactive message: the text alone first, then the buttons under a short line.
        if (mb_strlen($text) > self::BODY_MAX) {
            $first = self::post(['type' => 'text', 'text' => ['body' => $text, 'preview_url' => false]], $to);
            if ($first !== 'sent') {
                return $first;
            }
            $text = $ar ? 'اختر:' : 'Choose:';
        }

        return self::post(['type' => 'interactive', 'interactive' => self::interactive($text, $replies, $cta, $ar)], $to);
    }

    /** The interactive part: a link button, up to three reply buttons, or a list of up to ten rows. */
    public static function interactive(string $text, array $replies, ?array $cta, bool $ar): array
    {
        if ($cta) {
            return ['type' => 'cta_url', 'body' => ['text' => $text],
                'action' => ['name' => 'cta_url', 'parameters' => ['display_text' => mb_substr($cta[0], 0, 20), 'url' => substr($cta[1], 4)]]];
        }
        if (count($replies) <= 3) {
            return ['type' => 'button', 'body' => ['text' => $text],
                'action' => ['buttons' => array_map(fn ($b) => ['type' => 'reply', 'reply' => ['id' => mb_substr($b[1], 0, 256), 'title' => mb_substr($b[0], 0, 20)]], $replies)]];
        }
        // A label longer than a row's title (24) goes whole in its description.
        $rows = array_map(fn ($b) => ['id' => mb_substr($b[1], 0, 200), 'title' => mb_strlen($b[0]) > 24 ? mb_substr($b[0], 0, 23).'…' : $b[0]]
            + (mb_strlen($b[0]) > 24 ? ['description' => mb_substr($b[0], 0, 72)] : []), array_slice($replies, 0, self::ROWS_MAX));

        return ['type' => 'list', 'body' => ['text' => $text],
            'action' => ['button' => $ar ? 'اختر' : 'Choose', 'sections' => [['title' => $ar ? 'اختر' : 'Choose', 'rows' => $rows]]]];
    }

    /** [Sprint 70] His message is read (two blue ticks), and «typing…» shows until the answer arrives. */
    public static function seen(string $messageId): void
    {
        self::call(['messaging_product' => 'whatsapp', 'status' => 'read', 'message_id' => $messageId, 'typing_indicator' => ['type' => 'text']]);
    }

    /** [Sprint 70] What the bot's number is to Meta (its name, quality, whether it is verified), for messenger:setup. */
    public static function phone(): ?array
    {
        return self::get((string) config('services.whatsapp.phone_id'), ['fields' => 'display_phone_number,verified_name,quality_rating,code_verification_status,name_status']);
    }

    /** [Sprint 70] The profile people see when they open the bot's chat: about, description and the game's site. */
    public static function profile(string $about, string $description, string $site): bool
    {
        try {
            return self::client()->post(self::base().'/'.config('services.whatsapp.phone_id').'/whatsapp_business_profile', [
                'messaging_product' => 'whatsapp', 'about' => mb_substr($about, 0, 139), 'description' => mb_substr($description, 0, 512),
                'websites' => [$site], 'vertical' => 'ENTERTAIN'])->successful();
        } catch (Throwable) {
            return false;
        }
    }

    /** [Sprint 70] The app subscribed to the business account's webhooks (without it Meta sends nothing). */
    public static function subscribe(string $businessId): ?string
    {
        try {
            $r = self::client()->post(self::base()."/{$businessId}/subscribed_apps");

            return $r->successful() ? null : (string) $r->json('error.message', 'HTTP '.$r->status());
        } catch (Throwable $e) {
            return $e->getMessage();
        }
    }

    private static function post(array $message, string $to): string
    {
        return self::call(['messaging_product' => 'whatsapp', 'recipient_type' => 'individual', 'to' => $to] + $message);
    }

    private static function call(array $body): string
    {
        try {
            $r = self::client()->post(self::base().'/'.config('services.whatsapp.phone_id').'/messages', $body);
            if ($r->successful()) {
                return 'sent';
            }
            $code = (int) $r->json('error.code', 0);
            // What Meta refused and why, never the token or the text, so a failure on the server can be read.
            Log::warning('whatsapp: '.($body['status'] ?? $body['type'] ?? 'call').' refused', ['status' => $r->status(), 'code' => $code,
                'title' => (string) $r->json('error.error_data.details', $r->json('error.message', ''))]);

            // 131047: more than 24 hours since his last message.
            return $code === 131047 ? 'closed' : 'failed';
        } catch (Throwable) {
            return 'failed';
        }
    }

    private static function get(string $path, array $query): ?array
    {
        try {
            $r = self::client()->get(self::base().'/'.$path, $query);

            return $r->successful() ? (array) $r->json() : ['error' => (string) $r->json('error.message', 'HTTP '.$r->status())];
        } catch (Throwable $e) {
            return ['error' => $e->getMessage()];
        }
    }

    private static function client()
    {
        return Http::timeout((int) config('services.whatsapp.timeout'))->acceptJson()->withToken((string) config('services.whatsapp.token'));
    }

    private static function base(): string
    {
        return rtrim((string) config('services.whatsapp.url'), '/');
    }
}
