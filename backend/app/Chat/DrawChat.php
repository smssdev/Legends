<?php

namespace App\Chat;

use App\Events\DrawChatSent;
use App\Models\League;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [X66] The live draw's chat: whoever watches a tournament's draw says a line or sends an emoji reaction, and every
 * screen shows it at once (channel draw.{league}). Open from an hour before the draw until half an hour after its last
 * ball; kept, so a replay shows each at the moment it came. The author, the tournament's maker or an admin deletes it.
 */
class DrawChat
{
    /** When the chat opens and closes: around the draw's time (or its start when no time was set). */
    public static function window(League $league): array
    {
        $c = config('game.draw_chat');
        $at = $league->drawn_at ?? $league->draw_at ?? $league->starts_at;
        $length = (int) $league->team_count * (int) config('game.tournaments.reveal_ms');
        $from = Carbon::parse($at)->subMinutes($c['open_before']);
        $until = Carbon::parse($league->drawn_at ?? $at)->addMilliseconds($length)->addMinutes($c['open_after']);

        return [$from, $until];
    }

    public static function isOpen(League $league): bool
    {
        [$from, $until] = self::window($league);
        $now = GameClock::now();

        return $now->gte($from) && $now->lte($until);
    }

    public static function send(League $league, User $user, string $kind, string $body): array
    {
        $c = config('game.draw_chat');
        if ($league->kind !== 'tournament') {
            throw new HttpException(404, __('البطولة غير موجودة.'));
        }
        if (! self::isOpen($league)) {
            throw new HttpException(409, __('الدردشة مفتوحة قبل القرعة بساعة حتى نصف ساعة بعدها.'));
        }
        $body = trim($body);
        if ($kind === 'emoji' && ! in_array($body, $c['reactions'], true)) {
            throw new HttpException(422, __('اختر تفاعلاً من القائمة.'));
        }
        if ($kind === 'text' && ($body === '' || mb_strlen($body) > $c['max_length'])) {
            throw new HttpException(422, __('الرسالة فارغة أو أطول من المسموح.'));
        }
        $recent = DB::table('draw_chat')->where('league_id', $league->id)->where('user_id', $user->id)->where('kind', $kind)
            ->where('created_at', '>', GameClock::now()->subMinute())->count();
        if ($recent >= ($kind === 'emoji' ? $c['reactions_per_minute'] : $c['per_minute'])) {
            throw new HttpException(429, __('رسائل كثيرة في دقيقة واحدة. انتظر قليلاً.'));
        }
        $id = DB::table('draw_chat')->insertGetId(['league_id' => $league->id, 'user_id' => $user->id, 'kind' => $kind, 'body' => $body,
            'created_at' => GameClock::now()]);
        $view = self::views(collect([DB::table('draw_chat')->find($id)]))[0];
        DrawChatSent::dispatch($league->id, $view);

        return $view;
    }

    /** The chat so far (or after an id), oldest first. */
    public static function list(League $league, ?int $after = null): array
    {
        $rows = DB::table('draw_chat')->where('league_id', $league->id)->when($after, fn ($q, $a) => $q->where('id', '>', $a))
            ->orderByDesc('id')->limit(config('game.draw_chat.page'))->get()->reverse()->values();

        return self::views($rows);
    }

    public static function delete(League $league, User $user, int $id): void
    {
        $m = DB::table('draw_chat')->where('id', $id)->where('league_id', $league->id)->whereNull('deleted_at')->first();
        if (! $m || ((int) $m->user_id !== $user->id && ! $league->isOwner($user) && $user->role !== 'admin')) {
            throw new HttpException(403, __('تحذف رسائلك فقط.'));
        }
        DB::table('draw_chat')->where('id', $id)->update(['deleted_at' => GameClock::now()]);
        DrawChatSent::dispatch($league->id, self::views(collect([DB::table('draw_chat')->find($id)]))[0]);
    }

    /** With the chat groups' messages: everything older than the admin's retention goes. */
    public static function prune(int $days): int
    {
        return $days < 1 ? 0 : DB::table('draw_chat')->where('created_at', '<', GameClock::now()->subDays($days))->delete();
    }

    public static function views($rows): array
    {
        $users = DB::table('users')->whereIn('id', $rows->pluck('user_id')->filter()->unique()->all())->get(['id', 'name'])->keyBy('id');

        return $rows->map(fn ($m) => ['id' => (int) $m->id, 'kind' => $m->kind, 'deleted' => $m->deleted_at !== null,
            'body' => $m->deleted_at ? '' : $m->body,
            'user' => $m->user_id && isset($users[$m->user_id]) ? ['id' => (int) $m->user_id, 'name' => $users[$m->user_id]->name] : null,
            'at' => Carbon::parse($m->created_at, 'UTC')->getTimestampMs()])->values()->all();
    }
}
