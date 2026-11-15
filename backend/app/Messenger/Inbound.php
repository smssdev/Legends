<?php

namespace App\Messenger;

use App\Jobs\HandleInline;
use App\Jobs\HandleMessenger;
use App\Jobs\SendMessenger;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\RateLimiter;

/**
 * [Sprint 67] What Telegram and WhatsApp send to the game's webhooks, read into one shape: the platform, the chat, the
 * text (a tapped button's command), and for a Telegram group who wrote. Each message once (they resend what was not
 * answered quickly), each chat within game.messenger.per_minute, and the answer made on the queue, so the webhook
 * answers at once.
 */
class Inbound
{
    public static function telegram(array $update): void
    {
        $id = (string) ($update['update_id'] ?? '');
        if ($id === '' || ! Cache::add("messenger:seen:telegram:{$id}", true, 86400)) {
            return;
        }
        // [Sprint 69] «@bot» typed in any chat: answered on the queue, quickly.
        if (isset($update['inline_query']['id'], $update['inline_query']['from']['id'])) {
            HandleInline::dispatch((string) $update['inline_query']['id'], (string) $update['inline_query']['from']['id'], (string) ($update['inline_query']['query'] ?? ''));

            return;
        }
        // [Sprint 70] The bot added to a group: it says what it does there and how the league's owner links it.
        if (isset($update['my_chat_member']['chat']['id'])) {
            $c = $update['my_chat_member'];
            if (in_array($c['chat']['type'] ?? '', ['group', 'supergroup'], true) && in_array($c['old_chat_member']['status'] ?? '', ['left', 'kicked'], true)
                && in_array($c['new_chat_member']['status'] ?? '', ['member', 'administrator'], true)) {
                SendMessenger::dispatch('telegram', (string) $c['chat']['id'], LeagueGroups::welcome());
            }

            return;
        }
        if (isset($update['callback_query'])) {
            $q = $update['callback_query'];
            $chat = $q['message']['chat'] ?? null;
            Telegram::answerButton((string) $q['id']);
            if (($chat['type'] ?? '') === 'private' && is_string($q['data'] ?? null)) {
                self::queue('telegram', (string) $chat['id'], $q['data']);
            }

            return;
        }
        $m = $update['message'] ?? null;
        if (! is_array($m) || ! isset($m['chat']['id'])) {
            return;
        }
        $text = is_string($m['text'] ?? null) ? $m['text'] : '';
        if (($m['chat']['type'] ?? '') === 'private') {
            self::queue('telegram', (string) $m['chat']['id'], $text);

            return;
        }
        // In a group only the bot's own commands are read; the members' talk is not the game's business, unless the
        // league's owner joined the group to the game's chat [Sprint 69] (each writer within his own limit).
        if (! isset($m['from']['id']) || $text === '') {
            return;
        }
        if (str_starts_with($text, '/') || DB::table('messenger_groups')->where('chat_id', (string) $m['chat']['id'])->where('bridge', true)->exists()) {
            self::queue('telegram', (string) $m['chat']['id'], $text, (string) $m['from']['id']);
        }
    }

    public static function whatsapp(array $payload): void
    {
        foreach ($payload['entry'] ?? [] as $entry) {
            foreach ($entry['changes'] ?? [] as $change) {
                foreach ($change['value']['messages'] ?? [] as $m) {
                    $from = preg_replace('/\D/', '', (string) ($m['from'] ?? ''));
                    $id = (string) ($m['id'] ?? '');
                    if ($from === '' || $id === '' || ! Cache::add("messenger:seen:whatsapp:{$id}", true, 86400)) {
                        continue;
                    }
                    // His own message opens the free 24 hours again, whatever it is.
                    Messenger::heard('whatsapp', $from);
                    $text = match ($m['type'] ?? '') {
                        'text' => (string) ($m['text']['body'] ?? ''),
                        'interactive' => (string) ($m['interactive']['button_reply']['id'] ?? $m['interactive']['list_reply']['id'] ?? ''),
                        'button' => (string) ($m['button']['payload'] ?? $m['button']['text'] ?? ''),
                        default => '',
                    };
                    self::queue('whatsapp', $from, $text, null, $id);
                }
            }
        }
    }

    private static function queue(string $platform, string $chatId, string $text, ?string $from = null, ?string $messageId = null): void
    {
        $key = "messenger:{$platform}:{$chatId}".($from !== null ? ":{$from}" : '');
        if (RateLimiter::tooManyAttempts($key, (int) config('game.messenger.per_minute'))) {
            return;
        }
        RateLimiter::hit($key, 60);
        HandleMessenger::dispatch($platform, $chatId, mb_substr($text, 0, 1000), $from, $messageId);
    }
}
