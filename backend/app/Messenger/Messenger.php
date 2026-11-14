<?php

namespace App\Messenger;

use App\Jobs\SendMessenger;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * [Sprint 67] The game's bots on Telegram and WhatsApp, official and free:
 *  - a coach links his account once (a code from his profile, sent to the bot), then asks the bot about his clubs and
 *    the game (Replies);
 *  - the notifications he wants reach him there too: on Telegram always, on WhatsApp only within 24 hours of his own
 *    last message, where Meta charges nothing;
 *  - the game's public Telegram channel gets the developers' announcements and the weekly table of coaches, and the
 *    admins ask either bot for the last post to copy into the WhatsApp channel (which has no free API);
 *  - a league's Telegram group, linked by its owner, gets each round's results.
 * Every message leaves from the queue after its transaction commits, so a slow Telegram or Meta never holds the game.
 */
class Messenger
{
    public const PLATFORMS = ['telegram', 'whatsapp'];

    private const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    public static function available(string $platform): bool
    {
        return $platform === 'telegram' ? Telegram::configured() && Telegram::username() !== null : WhatsApp::configured() && WhatsApp::number() !== null;
    }

    public static function clip(string $text): string
    {
        $max = (int) config('game.messenger.text_max');

        return mb_strlen($text) > $max ? mb_substr($text, 0, $max - 1).'…' : $text;
    }

    /** What the profile shows: each bot, whether it is on, and whether this account is linked to it. */
    public static function status(int $userId): array
    {
        $links = DB::table('messenger_links')->where('user_id', $userId)->get()->keyBy('platform');
        $out = [];
        foreach (self::PLATFORMS as $p) {
            $link = $links[$p] ?? null;
            $out[$p] = ['available' => self::available($p), 'linked' => $link !== null, 'muted' => (bool) ($link->muted ?? false),
                // [Sprint 68] His live matches on this bot, and his daily summary's Cairo hour (null: off).
                'live' => (bool) ($link->live ?? true), 'daily_hour' => isset($link->daily_hour) ? (int) $link->daily_hour : null,
                'open_url' => self::openUrl($p, null)];
        }
        if (isset($out['whatsapp'])) {
            $out['whatsapp']['window_open'] = isset($links['whatsapp']) && self::windowOpen($links['whatsapp']->last_inbound_at);
        }
        $out['channels'] = ['telegram' => self::telegramChannelUrl(), 'whatsapp' => ((string) config('services.whatsapp.channel')) ?: null];

        return $out;
    }

    /** [Sprint 67] What every page of the site may open, signed in or not: the two bots and the two channels. */
    public static function links(): array
    {
        return ['telegram' => self::openUrl('telegram', null), 'whatsapp' => self::openUrl('whatsapp', null),
            'telegram_channel' => self::telegramChannelUrl(), 'whatsapp_channel' => ((string) config('services.whatsapp.channel')) ?: null];
    }

    /**
     * The link that opens the bot's chat, with the code already written when there is one; on WhatsApp without a code
     * a greeting is written, so one tap on send gets the menu (and opens the free window).
     */
    public static function openUrl(string $platform, ?string $code): ?string
    {
        if (! self::available($platform)) {
            return null;
        }
        if ($platform === 'telegram') {
            return 'https://t.me/'.Telegram::username().($code ? '?start='.$code : '');
        }

        return 'https://wa.me/'.WhatsApp::number().'?text='.rawurlencode($code ? 'ربط '.$code : 'مرحبا');
    }

    /**
     * [Sprint 67 X] TELEGRAM_CHANNEL as written on the server, in any of its usual forms: «name», «@name», «t.me/name»,
     * «https://t.me/name», a private channel's number «-100…», or its invite link «https://t.me/+…». Returns where the
     * bot posts (an @name or the number; null for an invite link, which the bot cannot post to) and the link people
     * open (TELEGRAM_CHANNEL_URL wins, for a private channel; null when there is none).
     *
     * @return array{chat: ?string, url: ?string}
     */
    public static function telegramChannel(): array
    {
        $raw = trim((string) config('services.telegram.channel'));
        $url = trim((string) config('services.telegram.channel_url')) ?: null;
        if (preg_match('/^-?\d+$/', $raw)) {
            return ['chat' => $raw, 'url' => $url];
        }
        $path = preg_replace('#^(https?://)?(www\.)?(t\.me|telegram\.me)/(s/)?#i', '', $raw) ?? '';
        $name = ltrim(strtok($path, '/?#') ?: '', '@');
        if (preg_match('/^[A-Za-z][A-Za-z0-9_]{3,31}$/', $name)) {
            return ['chat' => '@'.$name, 'url' => $url ?? 'https://t.me/'.$name];
        }

        // An invite link (t.me/+… or joinchat): people can open it, the bot cannot post by it.
        return ['chat' => null, 'url' => $url ?? (str_starts_with($raw, 'http') ? $raw : null)];
    }

    private static function telegramChannelUrl(): ?string
    {
        return self::telegramChannel()['url'];
    }

    /** A new one-time code for this account (the older ones go). */
    public static function code(int $userId): array
    {
        // With a digit always, so a word sent to the bot is never taken for a code.
        do {
            $code = '';
            for ($i = 0; $i < 8; $i++) {
                $code .= self::ALPHABET[random_int(0, strlen(self::ALPHABET) - 1)];
            }
        } while (! self::looksLikeCode($code));
        $expires = GameClock::now()->addMinutes((int) config('game.messenger.code_minutes'));
        DB::transaction(function () use ($userId, $code, $expires) {
            DB::table('messenger_codes')->where('user_id', $userId)->orWhere('expires_at', '<', GameClock::now())->delete();
            DB::table('messenger_codes')->insert(['code' => $code, 'user_id' => $userId, 'expires_at' => $expires]);
        });

        return ['code' => $code, 'expires_at' => $expires->toIso8601String()];
    }

    public static function looksLikeCode(string $s): bool
    {
        return (bool) preg_match('/^['.self::ALPHABET.']{8}$/', strtoupper($s)) && (bool) preg_match('/\d/', $s);
    }

    /**
     * The code sent from a chat links that chat to the code's account, once: the code is taken by a conditional delete,
     * so two chats sending it at once never both link. A chat linked to another account before is moved to this one.
     */
    public static function claim(string $platform, string $chatId, string $code): ?int
    {
        $code = strtoupper(trim($code));

        return DB::transaction(function () use ($platform, $chatId, $code) {
            $userId = DB::table('messenger_codes')->where('code', $code)->where('expires_at', '>', GameClock::now())->value('user_id');
            if (! $userId || DB::table('messenger_codes')->where('code', $code)->delete() !== 1) {
                return null;
            }
            DB::table('messenger_links')->where('platform', $platform)->where(fn ($q) => $q->where('chat_id', $chatId)->orWhere('user_id', $userId))->delete();
            $now = GameClock::now();
            DB::table('messenger_links')->insert(['user_id' => $userId, 'platform' => $platform, 'chat_id' => $chatId, 'muted' => false,
                'last_inbound_at' => $platform === 'whatsapp' ? $now : null, 'linked_at' => $now]);

            return (int) $userId;
        });
    }

    public static function userFor(string $platform, string $chatId): ?int
    {
        $id = DB::table('messenger_links')->where('platform', $platform)->where('chat_id', $chatId)->value('user_id');

        return $id ? (int) $id : null;
    }

    public static function unlink(int $userId, string $platform): bool
    {
        return DB::table('messenger_links')->where('user_id', $userId)->where('platform', $platform)->delete() > 0;
    }

    public static function mute(int $userId, string $platform, bool $muted): void
    {
        self::settings($userId, $platform, ['muted' => $muted]);
    }

    /** [Sprint 68] A linked bot's settings: muted, live, daily_hour (only these). */
    public static function settings(int $userId, string $platform, array $values): void
    {
        $values = array_intersect_key($values, array_flip(['muted', 'live', 'daily_hour']));
        if ($values) {
            DB::table('messenger_links')->where('user_id', $userId)->where('platform', $platform)->update($values);
        }
    }

    /** The coach wrote: WhatsApp's free window opens again for 24 hours. */
    public static function heard(string $platform, string $chatId): void
    {
        DB::table('messenger_links')->where('platform', $platform)->where('chat_id', $chatId)->update(['last_inbound_at' => GameClock::now()]);
    }

    public static function windowOpen(mixed $lastInbound): bool
    {
        return $lastInbound !== null && GameClock::now()->subHours((int) config('game.messenger.whatsapp_window_hours'))->lt($lastInbound);
    }

    /**
     * A notification the account wants (App\Notify\Push decided the kind) to each bot it linked and did not silence;
     * on WhatsApp only inside the free window. Returns how many were queued.
     */
    public static function notify(int $userId, string $title, string $body, ?string $link): int
    {
        $text = trim($title."\n".$body).($link ? "\n".rtrim((string) config('app.frontend_url'), '/').$link : '');
        $sent = 0;
        foreach (DB::table('messenger_links')->where('user_id', $userId)->where('muted', false)->get() as $l) {
            if (! self::available($l->platform) || ($l->platform === 'whatsapp' && ! self::windowOpen($l->last_inbound_at))) {
                continue;
            }
            SendMessenger::dispatch($l->platform, $l->chat_id, $text)->afterCommit();
            $sent++;
        }

        return $sent;
    }

    /**
     * [Sprint 68] A message of the game to an account on its linked bots (not silenced): $live for his live match
     * (only where he keeps those on), after $delay seconds (the minute's scene, so the bot never tells a goal before
     * the screen shows it). WhatsApp only inside its free window. Returns how many were queued.
     */
    public static function toUser(int $userId, callable $text, array|callable $buttons = [], int $delay = 0, bool $live = false): int
    {
        $n = 0;
        $links = DB::table('messenger_links')->join('users', 'users.id', '=', 'messenger_links.user_id')->where('messenger_links.user_id', $userId)
            ->where('messenger_links.muted', false)->when($live, fn ($q) => $q->where('messenger_links.live', true))
            ->get(['messenger_links.*', 'users.locale']);
        foreach ($links as $l) {
            if (! self::available($l->platform) || ($l->platform === 'whatsapp' && ! self::windowOpen($l->last_inbound_at))) {
                continue;
            }
            $en = $l->locale === 'en';
            SendMessenger::dispatch($l->platform, $l->chat_id, $text($en), false, is_callable($buttons) ? $buttons($en) : $buttons)
                ->delay(max(0, $delay))->afterCommit();
            $n++;
        }

        return $n;
    }

    /** A post to the game's public channel: sent to Telegram's, and kept for the admins to copy into WhatsApp's. */
    public static function post(string $kind, string $text): void
    {
        $now = GameClock::now();
        DB::table('messenger_posts')->insert(['kind' => $kind, 'text' => Str::limit($text, 3900, '…'), 'created_at' => $now]);
        $keep = DB::table('messenger_posts')->orderByDesc('id')->skip(20)->value('id');
        if ($keep) {
            DB::table('messenger_posts')->where('id', '<=', $keep)->delete();
        }
        $channel = self::telegramChannel()['chat'];
        if ($channel !== null && Telegram::configured()) {
            SendMessenger::dispatch('telegram', $channel, $text, true)->afterCommit();
        }
    }

    /** The last channel posts, newest first. */
    public static function posts(int $n = 3): array
    {
        return DB::table('messenger_posts')->orderByDesc('id')->limit($n)->pluck('text')->all();
    }
}
