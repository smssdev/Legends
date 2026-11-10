<?php

namespace App\League;

use App\Models\Club;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 50 M10] The daily tasks of the home screen's operations column: four small things a day, a few coins each.
 * The day runs midnight to midnight in Cairo. Like the weekly quests, progress is read from what the coach did that day
 * (nothing stored but the claims, in quest_claims with the day in place of the week and "d:" before the task):
 * the team set (the lineup or the tactics saved), a friendly, a player put in training, and a word in a chat group.
 */
class DailyTasks
{
    public const TASKS = ['lineup', 'friendly', 'training', 'chat'];

    public static function view(Club $club, int $userId): array
    {
        [$from, $to] = self::day();
        $claimed = DB::table('quest_claims')->where('club_id', $club->id)->where('week', $from->toDateString())
            ->whereLike('quest', 'd:%')->pluck('quest')->map(fn ($q) => substr($q, 2))->all();
        $done = self::progress($club, $userId, $from, $to);
        $coins = config('game.daily_tasks');
        $tasks = array_map(fn ($t) => ['task' => $t, 'complete' => $done[$t], 'claimed' => in_array($t, $claimed, true), 'coins' => (int) $coins[$t]], self::TASKS);

        return ['day' => $from->toDateString(), 'renews_at' => $to->copy()->utc()->toIso8601ZuluString(),
            'done' => count(array_filter($tasks, fn ($t) => $t['complete'])), 'total' => count($tasks), 'tasks' => $tasks];
    }

    public static function claim(Club $club, int $userId, string $task): array
    {
        $view = collect(self::view($club, $userId)['tasks'])->keyBy('task');
        abort_unless(isset($view[$task]), 404);
        if (! $view[$task]['complete']) {
            throw new HttpException(409, __('لم تكتمل هذه المهمة بعد.'));
        }
        [$from] = self::day();
        $day = $from->toDateString();
        DB::transaction(function () use ($club, $userId, $task, $day, $view) {
            if (DB::table('quest_claims')->insertOrIgnore(['club_id' => $club->id, 'week' => $day, 'quest' => "d:{$task}", 'claimed_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, __('أخذت مكافأة هذه المهمة من قبل.'));
            }
            Wallet::post($userId, 'daily_task', $view[$task]['coins'], "daily:{$club->id}:{$day}:{$task}", "daily:{$day}", $club->league_id);
        });

        return self::view($club, $userId);
    }

    /** What the coach did today, by task. */
    private static function progress(Club $club, int $userId, Carbon $from, Carbon $to): array
    {
        [$f, $t] = [$from->copy()->utc(), $to->copy()->utc()];

        return [
            'lineup' => DB::table('lineups')->where('club_id', $club->id)->whereBetween('updated_at', [$f, $t])->exists()
                || DB::table('tactics')->where('club_id', $club->id)->whereBetween('updated_at', [$f, $t])->exists(),
            'friendly' => DB::table('friendlies')->where('club_id', $club->id)->whereBetween('created_at', [$f, $t])->exists(),
            'training' => DB::table('training_slots')->where('club_id', $club->id)->whereBetween('created_at', [$f, $t])->exists(),
            'chat' => DB::table('chat_group_messages')->where('user_id', $userId)->where('kind', '!=', 'note')->whereBetween('created_at', [$f, $t])->exists(),
        ];
    }

    /** Today in Cairo: [00:00, tomorrow 00:00]. */
    private static function day(): array
    {
        $from = GameClock::now()->setTimezone('Africa/Cairo')->startOfDay();

        return [$from, $from->copy()->addDay()];
    }
}
