<?php

namespace App\Ideas;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 28] The polls on what to build next: the team opens one from the panel with its options (a suggestion's
 * among them, or any feature) for a set time (up to game.ideas.poll_max_days). Every account in the game votes once
 * and may change its vote while the poll is open. The counts show to a coach after voting and to everyone when it
 * ends, so nobody follows the crowd; the option with the most votes wins and goes first in the work.
 */
class Polls
{
    /** The polls a coach sees: the open ones, then those ended in the last 30 days. */
    public static function forCoach(int $userId): array
    {
        $now = GameClock::now();
        $rows = DB::table('polls')->where('starts_at', '<=', $now)->where('ends_at', '>', $now->copy()->subDays(30))
            ->orderByDesc('ends_at')->limit(20)->get();
        $mine = DB::table('poll_votes')->where('user_id', $userId)->whereIn('poll_id', $rows->pluck('id'))->pluck('option_id', 'poll_id');

        return $rows->map(fn ($p) => self::view($p, isset($mine[$p->id]) ? (int) $mine[$p->id] : null, false))
            ->sortBy(fn ($p) => $p['state'] === 'open' ? 0 : 1)->values()->all();
    }

    /** How many open polls this coach has not voted in yet (the home screen's dot). */
    public static function waiting(int $userId): int
    {
        $now = GameClock::now();

        return DB::table('polls')->where('starts_at', '<=', $now)->where('ends_at', '>', $now)
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))->from('poll_votes')->whereColumn('poll_votes.poll_id', 'polls.id')->where('poll_votes.user_id', $userId))
            ->count();
    }

    /** One vote an account, changed freely while the poll is open. */
    public static function vote(int $userId, int $pollId, int $optionId): array
    {
        $poll = DB::table('polls')->find($pollId);
        abort_unless($poll, 404, 'التصويت غير موجود.');
        abort_unless(self::state($poll) === 'open', 409, 'هذا التصويت ليس مفتوحاً الآن.');
        abort_unless(DB::table('poll_options')->where('id', $optionId)->where('poll_id', $pollId)->exists(), 422, 'اختر أحد خيارات هذا التصويت.');
        $now = GameClock::now();
        DB::transaction(function () use ($userId, $pollId, $optionId, $now) {
            $changed = DB::table('poll_votes')->where('poll_id', $pollId)->where('user_id', $userId)->update(['option_id' => $optionId, 'updated_at' => $now]);
            if ($changed === 0) {
                DB::table('poll_votes')->insertOrIgnore(['poll_id' => $pollId, 'option_id' => $optionId, 'user_id' => $userId, 'created_at' => $now, 'updated_at' => $now]);
            }
        });

        return self::view(DB::table('polls')->find($pollId), $optionId, false);
    }

    /**
     * The team opens a poll: the question, a word about it, its options (each a label, and the suggestion it came
     * from if any), when it starts (now by default) and how many hours it runs.
     */
    public static function open(int $adminId, array $data): array
    {
        $now = GameClock::now();
        $starts = isset($data['starts_at']) ? Carbon::parse($data['starts_at'])->utc() : $now->copy();
        $starts = $starts->lt($now) ? $now->copy() : $starts;
        $hours = (int) $data['hours'];
        $max = (int) config('game.ideas.poll_max_days');
        if ($hours < 1 || $hours > $max * 24) {
            throw new HttpException(422, sprintf(__('مدة التصويت من ساعة إلى %d يوماً.'), $max));
        }
        $labels = array_map(fn ($o) => trim((string) $o['label']), $data['options']);
        if (count(array_unique(array_map('mb_strtolower', $labels))) !== count($labels)) {
            throw new HttpException(422, 'خياران بالاسم نفسه.');
        }

        return DB::transaction(function () use ($adminId, $data, $starts, $hours, $now, $labels) {
            $id = DB::table('polls')->insertGetId(['question' => trim($data['question']), 'body' => isset($data['body']) ? trim((string) $data['body']) ?: null : null,
                'starts_at' => $starts, 'ends_at' => $starts->copy()->addHours($hours), 'user_id' => $adminId, 'created_at' => $now, 'updated_at' => $now]);
            foreach ($data['options'] as $i => $o) {
                DB::table('poll_options')->insert(['poll_id' => $id, 'label' => $labels[$i], 'suggestion_id' => $o['suggestion_id'] ?? null, 'position' => $i]);
            }

            return self::view(DB::table('polls')->find($id), null, true);
        });
    }

    /** One not started (or with no votes) is deleted; one running ends now; one ended stays as the record. */
    public static function close(int $id): bool
    {
        $poll = DB::table('polls')->find($id);
        abort_unless($poll, 404, 'التصويت غير موجود.');
        $state = self::state($poll);
        abort_if($state === 'ended', 409, 'انتهى هذا التصويت.');
        if ($state === 'upcoming' || ! DB::table('poll_votes')->where('poll_id', $id)->exists()) {
            DB::table('polls')->where('id', $id)->delete();

            return true;
        }
        DB::table('polls')->where('id', $id)->update(['ends_at' => GameClock::now(), 'updated_at' => GameClock::now()]);

        return false;
    }

    /** Every poll for the panel, with its counts at any time. */
    public static function forPanel(): array
    {
        return DB::table('polls')->orderByDesc('starts_at')->orderByDesc('id')->limit(100)->get()->map(fn ($p) => self::view($p, null, true))->all();
    }

    public static function state(object $poll): string
    {
        $now = GameClock::now();

        return Carbon::parse($poll->starts_at, 'UTC')->gt($now) ? 'upcoming' : (Carbon::parse($poll->ends_at, 'UTC')->gt($now) ? 'open' : 'ended');
    }

    /** A poll: its counts show to the team, to a coach who voted, and to everyone when it ends; the winners then. */
    public static function view(object $p, ?int $myVote, bool $team): array
    {
        $state = self::state($p);
        $counts = DB::table('poll_votes')->where('poll_id', $p->id)->select('option_id', DB::raw('count(*) as n'))->groupBy('option_id')->pluck('n', 'option_id');
        $total = (int) $counts->sum();
        $shown = $team || $myVote !== null || $state === 'ended';
        $options = DB::table('poll_options')->where('poll_id', $p->id)->orderBy('position')->orderBy('id')->get();
        $top = (int) $counts->max();
        $winners = $state === 'ended' && $top > 0 ? $options->filter(fn ($o) => (int) ($counts[$o->id] ?? 0) === $top)->pluck('id')->map(fn ($id) => (int) $id)->values()->all() : [];

        return ['id' => (int) $p->id, 'question' => $p->question, 'body' => $p->body, 'state' => $state,
            'starts_at' => Carbon::parse($p->starts_at, 'UTC')->toIso8601ZuluString(), 'ends_at' => Carbon::parse($p->ends_at, 'UTC')->toIso8601ZuluString(),
            'options' => $options->map(fn ($o) => ['id' => (int) $o->id, 'label' => $o->label, 'suggestion_id' => $o->suggestion_id ? (int) $o->suggestion_id : null,
                'votes' => $shown ? (int) ($counts[$o->id] ?? 0) : null])->all(),
            'total' => $shown ? $total : null, 'my_vote' => $myVote, 'winners' => $winners];
    }
}
