<?php

namespace App\Ideas;

use App\Admin\Announcements;
use App\Auth\Username;
use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 28] The coaches' suggestions to the developers: any account sends one (game.ideas.per_day in 24 hours),
 * the team answers it from the panel (accepted, built, or not taken) with a word, and one it likes may carry a reward
 * in coins, given once. Every accepted or built suggestion puts its coach on the honour roll of those who helped
 * make the game better.
 */
class Suggestions
{
    public const STATUSES = ['pending', 'accepted', 'built', 'rejected'];

    /** The statuses that put a coach on the honour roll. */
    public const HONOURED = ['accepted', 'built'];

    public static function send(User $user, string $title, string $body): array
    {
        $max = (int) config('game.ideas.per_day');
        if (self::sentToday($user->id) >= $max) {
            throw new HttpException(429, sprintf(__('أرسلت %d اقتراحات في آخر 24 ساعة، وهذا الحد. أرسل غيرها غداً.'), $max));
        }
        $now = GameClock::now();
        $id = DB::table('suggestions')->insertGetId(['user_id' => $user->id, 'title' => $title, 'body' => $body, 'status' => 'pending',
            'created_at' => $now, 'updated_at' => $now]);

        return self::view(DB::table('suggestions')->find($id));
    }

    public static function sentToday(int $userId): int
    {
        return DB::table('suggestions')->where('user_id', $userId)->where('created_at', '>', GameClock::now()->subDay())->count();
    }

    /** An account's own suggestions, newest first. */
    public static function mine(int $userId): array
    {
        return DB::table('suggestions')->where('user_id', $userId)->orderByDesc('id')->limit(50)->get()->map(fn ($s) => self::view($s))->all();
    }

    /**
     * The team decides: accepted, built or not taken, with a word, and a reward (only for one it likes, and only
     * once: a suggestion rewarded keeps its coins). The coach hears of it in the inbox.
     */
    public static function decide(User $admin, int $id, string $status, int $coins, ?string $reply): array
    {
        $now = GameClock::now();
        $s = DB::table('suggestions')->find($id);
        abort_unless($s, 404, 'الاقتراح غير موجود.');
        abort_if($status === 'rejected' && $coins > 0, 422, 'المكافأة لاقتراح أعجب الفريق فقط.');
        abort_if($coins > 0 && (int) $s->coins > 0, 409, 'أخذ هذا الاقتراح مكافأته من قبل.');
        abort_if($status === 'rejected' && in_array($s->status, self::HONOURED, true), 409, 'هذا الاقتراح مقبول، ولا يُرفض بعد ذلك.');
        abort_if($s->status === 'built' && $status !== 'built', 409, 'نُفّذ هذا الاقتراح في اللعبة.');

        DB::transaction(function () use ($admin, $s, $status, $coins, $reply, $now) {
            // The conditional update decides once if two developers answer together.
            $set = ['status' => $status, 'reply' => $reply, 'decided_by' => $admin->id, 'decided_at' => $now, 'updated_at' => $now];
            if ($coins > 0) {
                $set['coins'] = $coins;
            }
            $done = DB::table('suggestions')->where('id', $s->id)->where('status', $s->status)->where('coins', $s->coins)->update($set);
            if ($done !== 1) {
                throw new HttpException(409, 'تغيّر هذا الاقتراح الآن. افتحه من جديد.');
            }
            if ($coins > 0) {
                Wallet::post((int) $s->user_id, 'suggestion', $coins, 'suggestion:'.$s->id, 'admin:'.$admin->id);
            }
            DB::table('admin_log')->insert(['admin_id' => $admin->id, 'action' => 'suggestion', 'target_user_id' => $s->user_id,
                'details' => mb_substr("#{$s->id} {$status}".($coins > 0 ? " +{$coins}" : '').' · '.$s->title, 0, 300), 'created_at' => $now]);
        });
        Inbox::send((int) $s->user_id, 'suggestion_answer', ['title' => $s->title, 'status' => $status, 'coins' => $coins, 'reply' => (string) $reply]);

        return self::view(DB::table('suggestions')->find($id));
    }

    /** The panel's list: one status (or all), newest first, with each coach and the counts of each status. */
    public static function forPanel(?string $status): array
    {
        $rows = DB::table('suggestions')->join('users', 'users.id', '=', 'suggestions.user_id')
            ->when($status, fn ($q) => $q->where('suggestions.status', $status))->orderByDesc('suggestions.id')->limit(200)
            ->get(['suggestions.*', 'users.name', 'users.username', 'users.account_no']);

        return ['suggestions' => $rows->map(fn ($s) => self::view($s) + ['user' => ['id' => (int) $s->user_id, 'name' => $s->name, 'username' => $s->username, 'account_no' => $s->account_no]])->all(),
            'counts' => array_merge(array_fill_keys(self::STATUSES, 0), DB::table('suggestions')->select('status', DB::raw('count(*) as n'))->groupBy('status')->pluck('n', 'status')->map(fn ($n) => (int) $n)->all())];
    }

    /**
     * The honour roll: every coach with a suggestion the team liked, most first (then the latest), with how many,
     * the coins they earned, and their latest liked suggestion.
     */
    public static function honours(int $limit = 100): array
    {
        $rows = DB::table('suggestions')->whereIn('status', self::HONOURED)
            ->select('user_id', DB::raw('count(*) as n'), DB::raw('sum(coins) as coins'), DB::raw('max(id) as last_id'))
            ->groupBy('user_id')->orderByDesc('n')->orderByDesc('last_id')->limit($limit)->get();
        $users = DB::table('users')->leftJoin('user_avatars', 'user_avatars.user_id', '=', 'users.id')->whereIn('users.id', $rows->pluck('user_id'))
            ->get(['users.id', 'users.name', 'users.username', 'users.google_picture', 'user_avatars.updated_at as avatar_at'])->keyBy('id');
        $last = DB::table('suggestions')->whereIn('id', $rows->pluck('last_id'))->get(['id', 'title', 'status', 'decided_at'])->keyBy('id');

        return $rows->filter(fn ($r) => isset($users[$r->user_id]))->values()->map(function ($r, $i) use ($users, $last) {
            $u = $users[$r->user_id];
            $l = $last[$r->last_id];

            return ['rank' => $i + 1, 'user' => ['id' => (int) $u->id, 'name' => $u->name, 'username' => Announcements::shown((string) $u->username),
                'official' => Username::official($u->username), 'avatar_url' => $u->avatar_at ? '/api/v1/users/'.$u->id.'/avatar?v='.strtotime($u->avatar_at) : $u->google_picture],
                'count' => (int) $r->n, 'coins' => (int) $r->coins, 'latest' => ['title' => $l->title, 'status' => $l->status,
                    'at' => $l->decided_at ? Carbon::parse($l->decided_at, 'UTC')->toIso8601ZuluString() : null]];
        })->all();
    }

    public static function view(object $s): array
    {
        return ['id' => (int) $s->id, 'title' => $s->title, 'body' => $s->body, 'status' => $s->status, 'coins' => (int) $s->coins,
            'reply' => $s->reply, 'at' => Carbon::parse($s->created_at, 'UTC')->toIso8601ZuluString(),
            'decided_at' => $s->decided_at ? Carbon::parse($s->decided_at, 'UTC')->toIso8601ZuluString() : null];
    }
}
