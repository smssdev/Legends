<?php

namespace App\Chat;

use App\Events\ChatMessageSent;
use App\Messages\Inbox;
use App\Messenger\ChatBridge;
use App\Models\League;
use App\Models\User;
use App\Support\Avatar;
use App\Support\GameClock;
use App\Support\GameSettings;
use App\Support\LiveEvents;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 29] Chat groups, as in WhatsApp: any coach makes one and adds others by their username or a link; its
 * maker is its admin (and may make others admins), who adds, removes and renames. Every league and tournament has its
 * own group, kept in step with its coaches. A message reaches every member's screen at once on the group's channel;
 * a member deletes his own (an admin any), and the group shows "deleted" in its place.
 */
class ChatGroups
{
    private const CODE_ALPHABET = 'abcdefghjkmnpqrstuvwxyz23456789';

    public static function create(User $owner, string $name, array $usernames = []): int
    {
        if (DB::table('chat_group_members')->where('user_id', $owner->id)->count() >= config('game.chat.max_groups')) {
            throw new HttpException(409, __('وصلت إلى أقصى عدد من الجروبات.'));
        }

        return DB::transaction(function () use ($owner, $name, $usernames) {
            $now = GameClock::now();
            $id = DB::table('chat_groups')->insertGetId(['name' => $name, 'owner_id' => $owner->id, 'invite_code' => self::code(), 'created_at' => $now, 'updated_at' => $now]);
            self::join($id, $owner->id, true);
            self::note($id, 'created', ['by' => $owner->name]);
            if ($usernames) {
                self::add($id, $owner, $usernames);
            }

            return $id;
        });
    }

    /** The group of a league or tournament, made the first time and kept in step with its owner and coaches. */
    public static function forLeague(League $league): int
    {
        return DB::transaction(function () use ($league) {
            $now = GameClock::now();
            $id = DB::table('chat_groups')->where('league_id', $league->id)->value('id');
            if (! $id) {
                DB::table('chat_groups')->insertOrIgnore(['name' => $league->name, 'owner_id' => $league->owner_id, 'league_id' => $league->id,
                    'invite_code' => self::code(), 'created_at' => $now, 'updated_at' => $now]);
                $id = DB::table('chat_groups')->where('league_id', $league->id)->value('id');
            }
            // [X68] And a tournament's entrants, before the draw gives them their teams.
            $members = DB::table('clubs')->where('league_id', $league->id)->whereNotNull('user_id')->pluck('user_id')
                ->merge(DB::table('tournament_entries')->where('league_id', $league->id)->pluck('user_id'))
                ->push($league->owner_id)->filter()->unique()->map(fn ($v) => (int) $v)->values()->all();
            foreach ($members as $u) {
                self::join($id, $u, $u === (int) $league->owner_id);
            }
            DB::table('chat_group_members')->where('chat_group_id', $id)->whereNotIn('user_id', $members ?: [0])->delete();

            return (int) $id;
        });
    }

    /** An admin adds coaches by username; each hears it in his inbox. Returns how many were added. */
    public static function add(int $groupId, User $by, array $usernames): int
    {
        $group = self::group($groupId);
        self::assertAdmin($groupId, $by->id);
        if ($group->league_id) {
            throw new HttpException(409, __('أعضاء جروب الدوري هم مدربوه، ويتغيرون معه.'));
        }
        $users = DB::table('users')->whereIn('username', array_map(fn ($u) => strtolower(ltrim(trim((string) $u), '@')), $usernames))->get(['id', 'name']);
        if ($users->isEmpty()) {
            throw new HttpException(422, __('لا يوجد مدرب بهذا الاسم.'));
        }
        $count = DB::table('chat_group_members')->where('chat_group_id', $groupId)->count();
        $added = 0;
        foreach ($users as $u) {
            if ($count + $added >= config('game.chat.max_members')) {
                throw new HttpException(409, __('اكتمل عدد أعضاء الجروب.'));
            }
            if (self::join($groupId, (int) $u->id)) {
                $added++;
                self::note($groupId, 'added', ['by' => $by->name, 'name' => $u->name]);
                Inbox::send((int) $u->id, 'chat_invite', ['by' => $by->name, 'group' => $group->name, 'group_id' => $groupId]);
            }
        }

        return $added;
    }

    /** Anyone with the group's link joins it (not a league's group: its members are its coaches). */
    public static function joinByCode(User $user, string $code): int
    {
        $group = DB::table('chat_groups')->where('invite_code', strtolower($code))->first();
        if (! $group || $group->league_id) {
            throw new HttpException(404, __('رابط الجروب غير صحيح.'));
        }
        if (DB::table('chat_group_members')->where('chat_group_id', $group->id)->count() >= config('game.chat.max_members')) {
            throw new HttpException(409, __('اكتمل عدد أعضاء الجروب.'));
        }
        if (self::join($group->id, $user->id)) {
            self::note($group->id, 'joined', ['name' => $user->name]);
        }

        return (int) $group->id;
    }

    public static function leave(int $groupId, User $user): void
    {
        $group = self::group($groupId);
        if ($group->league_id) {
            throw new HttpException(409, __('تبقى في جروب الدوري ما دمت مدرباً فيه.'));
        }
        self::assertMember($groupId, $user->id);
        DB::transaction(function () use ($groupId, $user) {
            DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $user->id)->delete();
            self::note($groupId, 'left', ['name' => $user->name]);
            // The last admin gone: the longest member becomes one.
            if (! DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('is_admin', true)->exists()) {
                $next = DB::table('chat_group_members')->where('chat_group_id', $groupId)->orderBy('id')->value('id');
                if ($next) {
                    DB::table('chat_group_members')->where('id', $next)->update(['is_admin' => true]);
                }
            }
        });
    }

    public static function remove(int $groupId, User $by, int $userId): void
    {
        $group = self::group($groupId);
        self::assertAdmin($groupId, $by->id);
        if ($group->league_id || $userId === (int) $group->owner_id) {
            throw new HttpException(409, __('لا يمكن إخراج هذا العضو.'));
        }
        $name = DB::table('users')->where('id', $userId)->value('name');
        if (DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $userId)->delete()) {
            self::note($groupId, 'removed', ['by' => $by->name, 'name' => $name]);
        }
    }

    public static function setAdmin(int $groupId, User $by, int $userId, bool $admin): void
    {
        self::assertAdmin($groupId, $by->id);
        DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $userId)->update(['is_admin' => $admin, 'updated_at' => GameClock::now()]);
    }

    public static function rename(int $groupId, User $by, string $name): void
    {
        $group = self::group($groupId);
        self::assertAdmin($groupId, $by->id);
        if ($group->league_id) {
            throw new HttpException(409, __('اسم جروب الدوري هو اسم الدوري.'));
        }
        DB::table('chat_groups')->where('id', $groupId)->update(['name' => $name, 'updated_at' => GameClock::now()]);
        self::note($groupId, 'renamed', ['by' => $by->name, 'name' => $name]);
    }

    /** A member's message: text (emoji are text), at most per_minute a minute. */
    public static function send(int $groupId, User $user, string $body, ?int $replyTo = null): array
    {
        self::assertMember($groupId, $user->id);
        $body = trim($body);
        if ($body === '') {
            throw new HttpException(422, __('الرسالة فارغة.'));
        }

        return self::post($groupId, $user, 'text', $body, $replyTo);
    }

    /**
     * [X65] A picture (kept as a JPEG, at most image_px on its long side) or a voice note (as recorded, up to audio_kb
     * and audio_seconds), with an optional caption; while the admin allows media.
     */
    public static function sendMedia(int $groupId, User $user, string $kind, string $bytes, string $mime, string $caption = '', ?int $seconds = null, ?int $replyTo = null): array
    {
        self::assertMember($groupId, $user->id);
        if (! GameSettings::get('chat.media')) {
            throw new HttpException(403, __('إرسال الصور والصوت متوقف الآن.'));
        }
        $c = config('game.chat');
        if ($kind === 'image') {
            $bytes = Avatar::wide($bytes, $c['image_px'], $c['image_px']) ?? throw new HttpException(422, __('تعذرت قراءة الصورة، جرّب صورة أخرى.'));
            $mime = 'image/jpeg';
            $seconds = null;
        } else {
            $mime = strtolower(trim(explode(';', $mime)[0]));
            // A webm recording is read as video by its extension; it is a voice note here.
            $mime = $mime === 'video/webm' ? 'audio/webm' : $mime;
            if (! in_array($mime, $c['audio_mimes'], true) || strlen($bytes) > $c['audio_kb'] * 1024) {
                throw new HttpException(422, __('التسجيل الصوتي غير مقبول أو أطول من المسموح.'));
            }
            $seconds = max(1, min((int) $seconds, $c['audio_seconds']));
        }

        return DB::transaction(function () use ($groupId, $user, $kind, $bytes, $mime, $caption, $seconds, $replyTo) {
            return self::post($groupId, $user, $kind, trim($caption), $replyTo, function (int $id) use ($bytes, $mime, $seconds) {
                DB::table('chat_media')->insert(['chat_group_message_id' => $id, 'mime' => $mime, 'bytes' => strlen($bytes), 'seconds' => $seconds,
                    'data' => base64_encode($bytes), 'created_at' => GameClock::now()]);
            });
        });
    }

    /** A picture or voice note's bytes and type, for the group's members only. */
    public static function media(int $groupId, User $user, int $messageId): array
    {
        self::assertMember($groupId, $user->id);
        $m = DB::table('chat_media')->join('chat_group_messages', 'chat_group_messages.id', '=', 'chat_media.chat_group_message_id')
            ->where('chat_group_messages.id', $messageId)->where('chat_group_messages.chat_group_id', $groupId)->whereNull('chat_group_messages.deleted_at')
            ->first(['chat_media.mime', 'chat_media.data']);
        if (! $m) {
            throw new HttpException(404, __('الملف غير موجود.'));
        }

        return [base64_decode($m->data), $m->mime];
    }

    /**
     * [X65] The admin's retention: every message older than retention_days goes, its picture or voice note with it
     * (0 keeps them). Returns how many went.
     */
    public static function prune(?int $days = null): int
    {
        $days ??= (int) GameSettings::get('chat.retention_days');
        if ($days < 1) {
            return 0;
        }
        $before = GameClock::now()->subDays($days);
        $n = 0;
        do {
            $ids = DB::table('chat_group_messages')->where('created_at', '<', $before)->orderBy('id')->limit(500)->pluck('id')->all();
            if ($ids) {
                DB::table('chat_media')->whereIn('chat_group_message_id', $ids)->delete();
                DB::table('chat_group_messages')->whereIn('reply_to_id', $ids)->update(['reply_to_id' => null]);
                $n += DB::table('chat_group_messages')->whereIn('id', $ids)->delete();
            }
        } while (count($ids) === 500);

        // [X66] And the live draws' chat with them.
        return $n + DrawChat::prune($days);
    }

    private static function post(int $groupId, User $user, string $kind, string $body, ?int $replyTo, ?callable $then = null): array
    {
        // [Sprint 30 G6] A writer the admins kept out of the groups sends nothing.
        Moderation::assertNotBanned($user);
        // [Sprint 40 B3] A league's group is open until the league ends, then kept to read.
        $league = DB::table('chat_groups')->where('id', $groupId)->value('league_id');
        if ($league && DB::table('leagues')->where('id', $league)->value('status') === 'finished') {
            throw new HttpException(409, __('انتهى الدوري، وجروبه للقراءة فقط.'));
        }
        $recent = DB::table('chat_group_messages')->where('chat_group_id', $groupId)->where('user_id', $user->id)
            ->where('created_at', '>', GameClock::now()->subMinute())->count();
        if ($recent >= config('game.chat.per_minute')) {
            throw new HttpException(429, __('رسائل كثيرة في دقيقة واحدة. انتظر قليلاً.'));
        }
        if ($replyTo && ! DB::table('chat_group_messages')->where('id', $replyTo)->where('chat_group_id', $groupId)->exists()) {
            $replyTo = null;
        }
        $id = DB::table('chat_group_messages')->insertGetId(['chat_group_id' => $groupId, 'user_id' => $user->id, 'kind' => $kind,
            'body' => $body, 'reply_to_id' => $replyTo, 'created_at' => GameClock::now()]);
        if ($then) {
            $then($id);
        }
        DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $user->id)->update(['last_read_id' => $id]);
        DB::table('chat_groups')->where('id', $groupId)->update(['updated_at' => GameClock::now()]);
        $view = self::views(collect([DB::table('chat_group_messages')->find($id)]))[0];
        LiveEvents::send(new ChatMessageSent($groupId, $view));
        // [Sprint 69] And to the league's Telegram group, when its owner joined the two chats.
        ChatBridge::fromGame($groupId, $user, $kind, $body);

        return $view;
    }

    public static function delete(int $groupId, User $user, int $messageId): void
    {
        self::assertMember($groupId, $user->id);
        $m = DB::table('chat_group_messages')->where('id', $messageId)->where('chat_group_id', $groupId)->whereNull('deleted_at')->first();
        if (! $m || ((int) $m->user_id !== $user->id && ! self::isAdmin($groupId, $user->id))) {
            throw new HttpException(403, __('تحذف رسائلك فقط.'));
        }
        DB::table('chat_group_messages')->where('id', $messageId)->update(['deleted_at' => GameClock::now()]);
        // A deleted picture or voice note is gone, not hidden.
        DB::table('chat_media')->where('chat_group_message_id', $messageId)->delete();
        LiveEvents::send(new ChatMessageSent($groupId, self::views(collect([DB::table('chat_group_messages')->find($messageId)]))[0]));
    }

    /** A page of messages, oldest first, before a message id (the latest without it); reading it marks it read. */
    public static function messages(int $groupId, User $user, ?int $before = null): array
    {
        self::assertMember($groupId, $user->id);
        $rows = DB::table('chat_group_messages')->where('chat_group_id', $groupId)->when($before, fn ($q, $b) => $q->where('id', '<', $b))
            ->orderByDesc('id')->limit(config('game.chat.page'))->get()->reverse()->values();
        if (! $before && $rows->isNotEmpty()) {
            DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $user->id)
                ->where('last_read_id', '<', $rows->last()->id)->update(['last_read_id' => $rows->last()->id]);
        }

        return self::views($rows, $user->id);
    }

    /**
     * [Sprint 50 M8] A member's reaction on a message: one each, a new one takes the old one's place, the same one or
     * none takes it back. The message is sent again on the group's channel with its counts.
     */
    public static function react(int $groupId, User $user, int $messageId, ?string $reaction): array
    {
        self::assertMember($groupId, $user->id);
        $m = DB::table('chat_group_messages')->where('id', $messageId)->where('chat_group_id', $groupId)->whereNull('deleted_at')->first();
        if (! $m || $m->kind === 'note') {
            throw new HttpException(404, __('الرسالة غير موجودة.'));
        }
        DB::transaction(function () use ($user, $messageId, $reaction) {
            $old = DB::table('chat_group_reactions')->where('chat_group_message_id', $messageId)->where('user_id', $user->id)->value('reaction');
            DB::table('chat_group_reactions')->where('chat_group_message_id', $messageId)->where('user_id', $user->id)->delete();
            if ($reaction !== null && $reaction !== $old) {
                DB::table('chat_group_reactions')->insert(['chat_group_message_id' => $messageId, 'user_id' => $user->id,
                    'reaction' => $reaction, 'created_at' => GameClock::now()]);
            }
        });
        $row = DB::table('chat_group_messages')->find($messageId);
        LiveEvents::send(new ChatMessageSent($groupId, self::views(collect([$row]))[0]));

        return self::views(collect([$row]), $user->id)[0];
    }

    public static function read(int $groupId, User $user, int $lastId): void
    {
        DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $user->id)->where('last_read_id', '<', $lastId)->update(['last_read_id' => $lastId]);
    }

    /** The account's groups, the latest talk first, each with its last message and unread count. */
    public static function mine(User $user): array
    {
        $rows = DB::table('chat_group_members')->join('chat_groups', 'chat_groups.id', '=', 'chat_group_members.chat_group_id')
            ->where('chat_group_members.user_id', $user->id)->orderByDesc('chat_groups.updated_at')
            ->get(['chat_groups.*', 'chat_group_members.last_read_id', 'chat_group_members.is_admin', 'chat_group_members.muted']);

        return $rows->map(function ($g) use ($user) {
            $last = DB::table('chat_group_messages')->where('chat_group_id', $g->id)->orderByDesc('id')->first();

            return self::summary($g, $user) + [
                'last' => $last ? self::views(collect([$last]))[0] : null,
                'unread' => DB::table('chat_group_messages')->where('chat_group_id', $g->id)->where('id', '>', $g->last_read_id)
                    ->where('kind', '!=', 'note')->where('user_id', '!=', $user->id)->whereNull('deleted_at')->count(),
            ];
        })->values()->all();
    }

    public static function show(int $groupId, User $user): array
    {
        self::assertMember($groupId, $user->id);
        $g = self::group($groupId);
        $members = DB::table('chat_group_members')->join('users', 'users.id', '=', 'chat_group_members.user_id')->where('chat_group_id', $groupId)
            ->orderByDesc('is_admin')->orderBy('users.name')->get(['users.id', 'users.name', 'users.username', 'chat_group_members.is_admin']);

        return self::summary($g, $user) + [
            'members' => $members->map(fn ($m) => ['id' => (int) $m->id, 'name' => $m->name, 'username' => $m->username, 'is_admin' => (bool) $m->is_admin,
                'avatar_url' => url("/api/v1/users/{$m->id}/avatar")])->values()->all(),
        ];
    }

    private static function summary(object $g, User $user): array
    {
        $admin = self::isAdmin($g->id, $user->id);

        return ['id' => (int) $g->id, 'name' => $g->name, 'league_id' => $g->league_id ? (int) $g->league_id : null, 'is_admin' => $admin,
            'invite_url' => ! $g->league_id && $admin ? url('/groups/join/'.$g->invite_code) : null,
            'members_count' => DB::table('chat_group_members')->where('chat_group_id', $g->id)->count(),
            // [Sprint 40 B3] A finished league's group: kept to read, no more messages.
            'closed' => $g->league_id && DB::table('leagues')->where('id', $g->league_id)->value('status') === 'finished'];
    }

    /** Messages as the screens show them: who, what, when, and a short quote of what it answers. */
    public static function views($rows, ?int $viewer = null): array
    {
        // [Sprint 50 M8] The reactions' counts, and the viewer's own (none on the channel, where nobody is the viewer).
        $reacts = DB::table('chat_group_reactions')->whereIn('chat_group_message_id', $rows->pluck('id')->all())->get(['chat_group_message_id', 'user_id', 'reaction'])
            ->groupBy('chat_group_message_id');
        $users = DB::table('users')->whereIn('id', $rows->pluck('user_id')->filter()->unique()->all())->get(['id', 'name', 'username'])->keyBy('id');
        $replies = DB::table('chat_group_messages')->whereIn('id', $rows->pluck('reply_to_id')->filter()->unique()->all())->get()->keyBy('id');
        $media = DB::table('chat_media')->whereIn('chat_group_message_id', $rows->pluck('id')->all())->get(['chat_group_message_id', 'seconds'])->keyBy('chat_group_message_id');

        return $rows->map(function ($m) use ($users, $replies, $media, $reacts, $viewer) {
            $mine = $reacts[$m->id] ?? collect();
            $u = $m->user_id ? $users[$m->user_id] ?? null : null;
            $r = $m->reply_to_id ? $replies[$m->reply_to_id] ?? null : null;

            return ['id' => (int) $m->id, 'kind' => $m->kind, 'deleted' => $m->deleted_at !== null,
                'body' => $m->deleted_at ? '' : $m->body,
                'user' => $u ? ['id' => (int) $u->id, 'name' => $u->name, 'username' => $u->username] : null,
                'reply_to' => $r ? ['id' => (int) $r->id, 'kind' => $r->kind, 'body' => $r->deleted_at ? '' : mb_substr($r->body, 0, 80)] : null,
                // [X65] A picture's or voice note's address (members only) and a voice note's length.
                'media_url' => ! $m->deleted_at && isset($media[$m->id]) ? url("/api/v1/groups/{$m->chat_group_id}/media/{$m->id}") : null,
                'seconds' => isset($media[$m->id]) && $media[$m->id]->seconds !== null ? (int) $media[$m->id]->seconds : null,
                'reactions' => $m->deleted_at ? [] : $mine->countBy('reaction')->map(fn ($n) => (int) $n)->all(),
                'my_reaction' => $viewer && ! $m->deleted_at ? $mine->firstWhere('user_id', $viewer)?->reaction : null,
                'created_at' => Carbon::parse($m->created_at, 'UTC')->toIso8601ZuluString()];
        })->values()->all();
    }

    /** A note of the group's own ("X joined"), as JSON its screens put in words. */
    private static function note(int $groupId, string $what, array $data): void
    {
        $id = DB::table('chat_group_messages')->insertGetId(['chat_group_id' => $groupId, 'user_id' => null, 'kind' => 'note',
            'body' => json_encode(['what' => $what] + $data, JSON_UNESCAPED_UNICODE), 'created_at' => GameClock::now()]);
        LiveEvents::send(new ChatMessageSent($groupId, self::views(collect([DB::table('chat_group_messages')->find($id)]))[0]));
    }

    /** True when the account was not a member before. */
    private static function join(int $groupId, int $userId, bool $admin = false): bool
    {
        $now = GameClock::now();
        $last = (int) DB::table('chat_group_messages')->where('chat_group_id', $groupId)->max('id');

        return DB::table('chat_group_members')->insertOrIgnore(['chat_group_id' => $groupId, 'user_id' => $userId, 'is_admin' => $admin,
            'last_read_id' => $last, 'created_at' => $now, 'updated_at' => $now]) === 1;
    }

    private static function group(int $groupId): object
    {
        return DB::table('chat_groups')->find($groupId) ?? throw new HttpException(404, __('الجروب غير موجود.'));
    }

    public static function isAdmin(int $groupId, int $userId): bool
    {
        return DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $userId)->where('is_admin', true)->exists();
    }

    public static function assertMember(int $groupId, int $userId): void
    {
        if (! DB::table('chat_group_members')->where('chat_group_id', $groupId)->where('user_id', $userId)->exists()) {
            throw new HttpException(404, __('الجروب غير موجود.'));
        }
    }

    private static function assertAdmin(int $groupId, int $userId): void
    {
        self::assertMember($groupId, $userId);
        if (! self::isAdmin($groupId, $userId)) {
            throw new HttpException(403, __('هذا لمشرفي الجروب.'));
        }
    }

    private static function code(): string
    {
        do {
            $code = '';
            for ($i = 0; $i < 10; $i++) {
                $code .= self::CODE_ALPHABET[random_int(0, strlen(self::CODE_ALPHABET) - 1)];
            }
        } while (DB::table('chat_groups')->where('invite_code', $code)->exists());

        return $code;
    }
}
