<?php

namespace App\Notify;

use App\Jobs\SendPush;
use App\Messenger\Messenger;
use Illuminate\Support\Facades\DB;

/**
 * The one notifications channel [PLAN 2.13, Sprint 36]: an inbox message (or "your match is in 30 minutes") goes
 * to every browser the account subscribed, unless its kind is turned off. Web Push now; FCM joins the same channel
 * in Sprint 45. Sent from the queue after the transaction commits, so a slow push service never holds the game.
 */
class Push
{
    /** The kind a message type belongs to, or null when it does not push. */
    public static function kindOf(string $type): ?string
    {
        foreach (config('game.notifications.kinds') as $kind => $types) {
            if (in_array($type, $types, true)) {
                return $kind;
            }
        }

        return null;
    }

    public static function wants(int $userId, string $kind): bool
    {
        $prefs = json_decode((string) DB::table('users')->where('id', $userId)->value('notify_prefs'), true) ?: [];

        return ($prefs[$kind] ?? true) !== false;
    }

    public static function configured(): bool
    {
        return (bool) config('game.notifications.vapid.public') && (bool) config('game.notifications.vapid.private');
    }

    /**
     * Push to the account: title, body and the screen the tap opens, and [Sprint 19 F1] its league, so the app opens
     * that screen inside it. Returns whether anything was queued.
     */
    public static function send(int $userId, string $type, string $title, string $body, ?string $link, ?int $leagueId = null): bool
    {
        $kind = self::kindOf($type);
        if (! $kind || ! self::wants($userId, $kind)) {
            return false;
        }
        // [Sprint 67] The same notification to the game's bots the account linked (Telegram, WhatsApp in its free window).
        Messenger::notify($userId, $title, $body, $link);
        if (! DB::table('push_subscriptions')->where('user_id', $userId)->exists()) {
            return false;
        }
        SendPush::dispatch($userId, ['title' => $title, 'body' => $body, 'link' => $link ?? '/', 'tag' => $type] + ($leagueId ? ['league' => $leagueId] : []))->afterCommit();

        return true;
    }
}
