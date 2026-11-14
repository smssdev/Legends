<?php

namespace App\Messenger;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * [Sprint 67] Telegram's Bot API, official and free with no limit on who the bot writes to: a message (with buttons
 * under it), the answer to a tapped button, and the webhook the game listens on.
 */
class Telegram
{
    public static function configured(): bool
    {
        return (bool) config('services.telegram.token') && (bool) config('services.telegram.secret');
    }

    public static function username(): ?string
    {
        $name = ltrim((string) config('services.telegram.username'), '@');

        return $name !== '' ? $name : null;
    }

    /**
     * One message: plain text (no markup to escape), and buttons under it, each [label, command], two by row.
     * Returns 'sent', 'gone' when the chat no longer takes the bot's messages (he blocked it, the group removed it),
     * or 'failed'.
     */
    public static function send(string $chatId, string $text, array $buttons = []): string
    {
        $body = ['chat_id' => $chatId, 'text' => Messenger::clip($text), 'disable_web_page_preview' => true];
        if ($buttons) {
            $body['reply_markup'] = ['inline_keyboard' => array_chunk(array_map(fn ($b) => ['text' => $b[0], 'callback_data' => $b[1]], $buttons), 2)];
        }
        $r = self::call('sendMessage', $body);
        if ($r === null) {
            return 'failed';
        }

        return $r['ok'] ? 'sent' : (in_array($r['status'], [400, 403], true) && self::isGone($r['description']) ? 'gone' : 'failed');
    }

    public static function answerButton(string $callbackId): void
    {
        self::call('answerCallbackQuery', ['callback_query_id' => $callbackId]);
    }

    /** Points Telegram at the game's webhook, with the secret it sends back in every update. */
    public static function setWebhook(string $url): array
    {
        return self::call('setWebhook', ['url' => $url, 'secret_token' => config('services.telegram.secret'),
            'allowed_updates' => ['message', 'callback_query'], 'drop_pending_updates' => true]) ?? ['ok' => false, 'status' => 0, 'description' => 'no answer'];
    }

    /** The bot's own name, from its token (to fill TELEGRAM_BOT_USERNAME). */
    public static function me(): ?string
    {
        $r = self::call('getMe', []);

        return $r['ok'] ?? false ? ($r['result']['username'] ?? null) : null;
    }

    private static function isGone(string $why): bool
    {
        $why = strtolower($why);

        return str_contains($why, 'blocked') || str_contains($why, 'chat not found') || str_contains($why, 'kicked') || str_contains($why, 'deactivated');
    }

    private static function call(string $method, array $body): ?array
    {
        try {
            $r = Http::timeout((int) config('services.telegram.timeout'))->acceptJson()
                ->post(rtrim((string) config('services.telegram.url'), '/').'/bot'.config('services.telegram.token').'/'.$method, $body);

            return ['ok' => $r->successful() && ($r->json('ok') === true), 'status' => $r->status(),
                'description' => (string) $r->json('description', ''), 'result' => $r->json('result')];
        } catch (Throwable) {
            return null;
        }
    }
}
