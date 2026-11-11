<?php

namespace App\Chat;

use App\Events\ChatMessageSent;
use App\Models\User;
use App\Support\GameClock;
use App\Support\LiveEvents;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 30 G6] The groups' moderation queue: a member reports another's message (once each), the admins see the
 * reported messages the most reported first, and decide: leave it, remove it, or remove it and keep its writer out of
 * every group (users.chat_banned_at) until an admin lets him back. Every decision is the admin's, logged.
 */
class Moderation
{
    public const REASONS = ['abuse', 'inappropriate', 'spam', 'other'];

    public static function report(int $groupId, User $user, int $messageId, string $reason, ?string $note): void
    {
        ChatGroups::assertMember($groupId, $user->id);
        $m = DB::table('chat_group_messages')->where('id', $messageId)->where('chat_group_id', $groupId)->whereNull('deleted_at')->first();
        if (! $m || $m->user_id === null) {
            throw new HttpException(404, __('الرسالة غير موجودة.'));
        }
        if ((int) $m->user_id === $user->id) {
            throw new HttpException(422, __('لا تبلّغ عن رسالتك.'));
        }
        // Reported before by this coach: once is enough. Ignored by the database itself [X99], since a caught
        // duplicate would leave a PostgreSQL transaction aborted.
        DB::table('chat_reports')->insertOrIgnore(['chat_group_message_id' => $messageId, 'reporter_id' => $user->id, 'reason' => $reason,
            'note' => $note ? mb_substr(trim($note), 0, 300) : null, 'created_at' => GameClock::now()]);
    }

    /** The pending reports, one row per message, the most reported first. */
    public static function queue(): array
    {
        $rows = DB::table('chat_reports')->where('chat_reports.status', 'pending')
            ->join('chat_group_messages as m', 'm.id', '=', 'chat_reports.chat_group_message_id')
            ->join('chat_groups as g', 'g.id', '=', 'm.chat_group_id')
            ->leftJoin('users as w', 'w.id', '=', 'm.user_id')
            ->get(['chat_reports.*', 'm.body', 'm.kind', 'm.user_id as writer_id', 'm.created_at as sent_at', 'g.name as group', 'w.name as writer', 'w.username as writer_username', 'w.chat_banned_at']);

        return $rows->groupBy('chat_group_message_id')->map(function ($rs) {
            $f = $rs->first();

            return ['message_id' => (int) $f->chat_group_message_id, 'body' => $f->kind === 'text' ? $f->body : null, 'kind' => $f->kind, 'group' => $f->group,
                'writer' => ['id' => (int) $f->writer_id, 'name' => $f->writer, 'username' => $f->writer_username, 'banned' => $f->chat_banned_at !== null],
                'reports' => $rs->count(), 'reasons' => $rs->pluck('reason')->countBy()->all(), 'notes' => $rs->pluck('note')->filter()->values()->all()];
        })->sortByDesc('reports')->values()->all();
    }

    /** leave | remove | ban, for every report on that message at once. */
    public static function decide(int $messageId, User $admin, string $action): void
    {
        $m = DB::table('chat_group_messages')->find($messageId);
        abort_unless($m, 404);
        DB::transaction(function () use ($m, $admin, $action) {
            DB::table('chat_reports')->where('chat_group_message_id', $m->id)->where('status', 'pending')
                ->update(['status' => ['leave' => 'kept', 'remove' => 'removed', 'ban' => 'banned'][$action], 'decided_by' => $admin->id, 'decided_at' => GameClock::now()]);
            if ($action !== 'leave' && $m->deleted_at === null) {
                DB::table('chat_group_messages')->where('id', $m->id)->update(['deleted_at' => GameClock::now()]);
                DB::table('chat_media')->where('chat_group_message_id', $m->id)->delete();
            }
            if ($action === 'ban' && $m->user_id) {
                DB::table('users')->where('id', $m->user_id)->whereNull('chat_banned_at')->update(['chat_banned_at' => GameClock::now()]);
            }
        });
        if ($action !== 'leave') {
            LiveEvents::send(new ChatMessageSent((int) $m->chat_group_id, ChatGroups::views(collect([DB::table('chat_group_messages')->find($m->id)]))[0]));
        }
    }

    public static function assertNotBanned(User $user): void
    {
        // From the table, not the signed-in model: a ban reaches a session already open.
        if (DB::table('users')->where('id', $user->id)->whereNotNull('chat_banned_at')->exists()) {
            throw new HttpException(403, __('أوقفت الإدارة رسائلك في الجروبات. راسل فريق التطوير من الدعم.'));
        }
    }
}
