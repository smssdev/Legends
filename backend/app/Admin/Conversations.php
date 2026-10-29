<?php

namespace App\Admin;

use App\Auth\Username;
use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The developers' conversations with the coaches [Sprint 21 E7.7]: an official account (Owner-Sizar, Owner-Sliman)
 * writes to any coach from the admin panel, the coach answers from the game, and every developer sees the thread.
 * Each message a developer sends also lands in the coach's inbox (and phone) with the official badge.
 */
class Conversations
{
    public const MAX = 2000;

    /** One coach's thread, oldest first. */
    public static function thread(int $userId, int $limit = 100): array
    {
        $admins = DB::table('users')->whereIn('id', DB::table('support_messages')->where('user_id', $userId)->whereNotNull('admin_id')->distinct()->pluck('admin_id'))
            ->get(['id', 'name', 'username'])->keyBy('id');

        return DB::table('support_messages')->where('user_id', $userId)->orderByDesc('id')->limit($limit)->get()->reverse()->values()
            ->map(fn ($m) => ['id' => $m->id, 'body' => $m->body, 'from_team' => $m->admin_id !== null,
                'sender' => $m->admin_id && isset($admins[$m->admin_id]) ? ['name' => $admins[$m->admin_id]->name, 'username' => self::shown($admins[$m->admin_id]->username), 'official' => true] : null,
                'read' => $m->read_at !== null, 'at' => Carbon::parse($m->created_at, 'UTC')->toIso8601ZuluString()])->all();
    }

    /** A developer writes to a coach: the thread, and the coach's inbox with the official badge. */
    public static function fromTeam(User $admin, User $coach, string $body): void
    {
        abort_unless(Username::official($admin->username), 403, 'التواصل من حسابات المطورين الرسمية فقط (Owner-Sizar أو Owner-Sliman).');
        DB::table('support_messages')->insert(['user_id' => $coach->id, 'admin_id' => $admin->id, 'body' => $body, 'created_at' => GameClock::now()]);
        Inbox::send($coach->id, 'official_message', ['body' => mb_substr($body, 0, 300), 'from' => $admin->name, 'username' => self::shown($admin->username)]);
    }

    /** A coach writes to the team (a reply or a first word). */
    public static function fromCoach(User $coach, string $body): void
    {
        DB::table('support_messages')->insert(['user_id' => $coach->id, 'admin_id' => null, 'body' => $body, 'created_at' => GameClock::now()]);
    }

    /** The coach has read the team's messages; the team has read the coach's. */
    public static function markRead(int $userId, bool $team): void
    {
        DB::table('support_messages')->where('user_id', $userId)->whereNull('read_at')
            ->where(fn ($q) => $team ? $q->whereNull('admin_id') : $q->whereNotNull('admin_id'))->update(['read_at' => GameClock::now()]);
    }

    /** Every thread for the panel: the coach, the last message, and how many of the coach's the team has not read. */
    public static function inbox(): array
    {
        $last = DB::table('support_messages')->select('user_id', DB::raw('max(id) as last_id'))->groupBy('user_id');
        $unread = DB::table('support_messages')->whereNull('admin_id')->whereNull('read_at')->select('user_id', DB::raw('count(*) as n'))->groupBy('user_id')->pluck('n', 'user_id');

        return DB::table('support_messages as m')->joinSub($last, 'l', 'l.last_id', '=', 'm.id')->join('users', 'users.id', '=', 'm.user_id')
            ->orderByDesc('m.id')->limit(100)->get(['m.user_id', 'm.body', 'm.admin_id', 'm.created_at', 'users.name', 'users.username', 'users.account_no'])
            ->map(fn ($r) => ['user' => ['id' => $r->user_id, 'name' => $r->name, 'username' => $r->username, 'account_no' => $r->account_no],
                'last' => mb_substr($r->body, 0, 120), 'from_team' => $r->admin_id !== null, 'unread' => (int) ($unread[$r->user_id] ?? 0),
                'at' => Carbon::parse($r->created_at, 'UTC')->toIso8601ZuluString()])->all();
    }

    private static function shown(string $username): string
    {
        foreach (config('game.account.official_usernames') as $name) {
            if (strtolower($name) === $username) {
                return $name;
            }
        }

        return $username;
    }
}
