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
     * One message: plain text (no markup to escape), and buttons under it, each [label, command] (a command, sent back
     * as a tap) or [label, 'url:https://…'] (a link), two by row. [Sprint 68] Or, instead, $keyboard: the labels of the
     * buttons that stay under the chat (each sends its label as a message), by row. $replyTo answers a message.
     * Returns 'sent', 'gone' when the chat no longer takes the bot's messages (he blocked it, the group removed it),
     * or 'failed'.
     */
    public static function send(string $chatId, string $text, array $buttons = [], ?array $keyboard = null, ?int $replyTo = null): string
    {
        $body = ['chat_id' => $chatId, 'text' => Messenger::clip($text), 'disable_web_page_preview' => true];
        if ($buttons) {
            $body['reply_markup'] = ['inline_keyboard' => array_chunk(array_map(fn ($b) => str_starts_with($b[1], 'url:')
                ? ['text' => $b[0], 'url' => substr($b[1], 4)] : ['text' => $b[0], 'callback_data' => $b[1]], $buttons), 2)];
        } elseif ($keyboard) {
            $body['reply_markup'] = ['keyboard' => array_map(fn ($row) => array_map(fn ($label) => ['text' => $label], $row), $keyboard),
                'resize_keyboard' => true, 'is_persistent' => true];
        }
        if ($replyTo) {
            $body['reply_parameters'] = ['message_id' => $replyTo, 'allow_sending_without_reply' => true];
        }
        $r = self::call('sendMessage', $body);
        if ($r === null) {
            return 'failed';
        }

        return $r['ok'] ? 'sent' : (in_array($r['status'], [400, 403], true) && self::isGone($r['description']) ? 'gone' : 'failed');
    }

    /** [Sprint 68] A poll in a group: its message's id, or null when it could not be sent. */
    public static function poll(string $chatId, string $question, array $options): ?int
    {
        $r = self::call('sendPoll', ['chat_id' => $chatId, 'question' => mb_substr($question, 0, 300),
            'options' => array_map(fn ($o) => ['text' => mb_substr($o, 0, 100)], $options), 'is_anonymous' => true]);

        return ($r['ok'] ?? false) ? (int) ($r['result']['message_id'] ?? 0) ?: null : null;
    }

    public static function stopPoll(string $chatId, int $messageId): void
    {
        self::call('stopPoll', ['chat_id' => $chatId, 'message_id' => $messageId]);
    }

    /** [Sprint 68] The menu of commands Telegram shows by «/», in Arabic and in English. */
    public static function setCommands(array $commands, ?string $language = null): bool
    {
        $r = self::call('setMyCommands', ['commands' => array_map(fn ($c, $d) => ['command' => $c, 'description' => $d], array_keys($commands), $commands)]
            + ($language ? ['language_code' => $language] : []));

        return (bool) ($r['ok'] ?? false);
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

    /** [Sprint 67 X] Whether the bot can post in this chat: null when it can, or Telegram's reason. */
    public static function canPost(string $chatId): ?string
    {
        $chat = self::call('getChat', ['chat_id' => $chatId]);
        if (! ($chat['ok'] ?? false)) {
            return $chat['description'] ?? 'no answer';
        }
        $id = explode(':', (string) config('services.telegram.token'))[0];
        $member = self::call('getChatMember', ['chat_id' => $chatId, 'user_id' => $id]);
        $status = $member['result']['status'] ?? '';

        return in_array($status, ['administrator', 'creator'], true) ? null : 'the bot is not an admin of the channel';
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
