<?php

namespace App\Messenger;

use App\Chat\ChatGroups;
use App\Jobs\SendMessenger;
use App\Models\League;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

/**
 * [Sprint 69] A league's chat and its Telegram group as one, when the league's owner turns it on (/chat on): what a
 * member writes in the game's league group appears in the Telegram group under his name, and what a member writes in
 * the Telegram group appears in the game's, from his own account, by the game's own rules (ChatGroups::send: a member
 * only, not banned, the per-minute limit). A Telegram writer not linked to an account, or not a member, is not carried.
 * Text only: a picture or a voice note from the game is told by a line.
 */
class ChatBridge
{
    /** True while a Telegram message is being posted in the game, so it is not carried back. */
    private static bool $fromTelegram = false;

    /** A message posted in a game group: to the league's Telegram group, if it carries the chat. */
    public static function fromGame(int $groupId, User $user, string $kind, string $body): void
    {
        if (self::$fromTelegram || ! Telegram::configured()) {
            return;
        }
        $chat = DB::table('chat_groups')->join('messenger_groups', 'messenger_groups.league_id', '=', 'chat_groups.league_id')
            ->where('chat_groups.id', $groupId)->where('messenger_groups.bridge', true)->value('messenger_groups.chat_id');
        if (! $chat) {
            return;
        }
        $what = match ($kind) {
            'text' => $body,
            'image' => 'أرسل صورة في جروب اللعبة.',
            'audio' => 'أرسل رسالة صوتية في جروب اللعبة.',
            default => null,
        };
        if ($what !== null && trim($what) !== '') {
            SendMessenger::dispatch('telegram', (string) $chat, "{$user->name}: {$what}")->afterCommit();
        }
    }

    /** A Telegram group's message: into the league's game group, from the writer's own account. */
    public static function fromTelegram(string $chatId, string $from, string $text): void
    {
        $league = DB::table('messenger_groups')->where('chat_id', $chatId)->where('bridge', true)->value('league_id');
        $userId = Messenger::userFor('telegram', $from);
        $group = $league ? DB::table('chat_groups')->where('league_id', $league)->value('id') : null;
        $user = $userId ? User::find($userId) : null;
        if (! $group || ! $user || trim($text) === '') {
            return;
        }
        self::$fromTelegram = true;
        try {
            ChatGroups::send((int) $group, $user, mb_substr(trim($text), 0, (int) config('game.chat.max_length', 1000)));
        } catch (HttpExceptionInterface) {
            // Not a member, kept out, or too many messages: as in the game, it is not posted.
        } finally {
            self::$fromTelegram = false;
        }
    }

    /** The owner (or whoever linked the group) turns the bridge on or off. */
    public static function set(int $userId, string $chatId, bool $on): bool
    {
        $g = DB::table('messenger_groups')->where('chat_id', $chatId)->first();
        if (! $g || ((int) $g->linked_by !== $userId && (int) DB::table('leagues')->where('id', $g->league_id)->value('owner_id') !== $userId)) {
            return false;
        }
        DB::table('messenger_groups')->where('id', $g->id)->update(['bridge' => $on]);
        if ($on) {
            // The league's game group exists from now on, so the first Telegram message has where to go.
            ChatGroups::forLeague(League::find($g->league_id));
        }

        return true;
    }
}
