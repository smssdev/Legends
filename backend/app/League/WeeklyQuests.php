<?php

namespace App\League;

use App\Economy\Economy;
use App\Models\Club;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The weekly quests [Sprint 20 B5, the owner's decision 2026-10-29: a few coins each, club money for the big one].
 * The week runs Monday to Monday in Cairo. Progress is read from what the club did that week (nothing is counted
 * twice, nothing is stored but the claims): a friendly, league wins, a stadium part, a player's +1 from training,
 * and the big one, a week of at least two matches without a defeat. Each is claimed once a week.
 */
class WeeklyQuests
{
    public const QUESTS = ['friendly', 'wins', 'stadium', 'training', 'unbeaten'];

    public static function view(Club $club, int $userId): array
    {
        [$from, $to] = self::week();
        $claimed = DB::table('quest_claims')->where('club_id', $club->id)->where('week', $from->toDateString())->pluck('quest')->all();
        $cfg = config('game.quests');
        $done = self::progress($club, $userId, $from, $to);
        $quests = array_map(fn ($q) => ['quest' => $q, 'progress' => min($done[$q], $cfg[$q]['target']), 'target' => (int) $cfg[$q]['target'],
            'reward' => $q === 'unbeaten' ? ['money' => self::bigMoney($club)] : ['coins' => (int) $cfg[$q]['coins']],
            'complete' => $done[$q] >= $cfg[$q]['target'] && ($q !== 'unbeaten' || $done['lost'] === 0), 'claimed' => in_array($q, $claimed, true)], self::QUESTS);

        return ['week' => $from->toDateString(), 'renews_at' => $to->copy()->utc()->toIso8601ZuluString(), 'quests' => $quests];
    }

    public static function claim(Club $club, int $userId, string $quest): array
    {
        $view = collect(self::view($club, $userId)['quests'])->keyBy('quest');
        abort_unless(isset($view[$quest]), 404);
        if (! $view[$quest]['complete']) {
            throw new HttpException(409, 'لم تكتمل هذه المهمة بعد.');
        }
        [$from] = self::week();
        $week = $from->toDateString();
        DB::transaction(function () use ($club, $userId, $quest, $week, $view) {
            // Claimed once: the unique row decides, whichever tap comes first.
            if (DB::table('quest_claims')->insertOrIgnore(['club_id' => $club->id, 'week' => $week, 'quest' => $quest, 'claimed_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, 'أخذت مكافأة هذه المهمة من قبل.');
            }
            $key = "quest:{$club->id}:{$week}:{$quest}";
            if ($quest === 'unbeaten') {
                ClubLedger::post($club->id, 'quest', $view[$quest]['reward']['money'], $key, "quest:{$week}");
            } else {
                Wallet::post($userId, 'quest', $view[$quest]['reward']['coins'], $key, "quest:{$week}", $club->league_id);
            }
        });

        return self::view($club, $userId);
    }

    /** What the club did this week, by quest (and its league defeats, for the big one). */
    private static function progress(Club $club, int $userId, Carbon $from, Carbon $to): array
    {
        [$f, $t] = [$from->copy()->utc(), $to->copy()->utc()];
        $results = DB::table('fixtures')->where('status', 'finished')->where('is_bye', false)->whereBetween('scheduled_at', [$f, $t])
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->get(['home_id', 'home_goals', 'away_goals', 'competition'])
            ->map(fn ($r) => (int) $r->home_id === $club->id ? $r->home_goals <=> $r->away_goals : $r->away_goals <=> $r->home_goals);
        $league = DB::table('fixtures')->where('status', 'finished')->where('competition', 'league')->where('is_bye', false)->whereBetween('scheduled_at', [$f, $t])
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->get(['home_id', 'home_goals', 'away_goals'])
            ->filter(fn ($r) => ((int) $r->home_id === $club->id ? $r->home_goals <=> $r->away_goals : $r->away_goals <=> $r->home_goals) === 1)->count();

        return [
            'friendly' => DB::table('friendlies')->where('club_id', $club->id)->whereBetween('created_at', [$f, $t])->count(),
            'wins' => $league,
            'stadium' => DB::table('stadium_builds')->where('club_id', $club->id)->where('status', 'done')->whereBetween('ends_at', [$f, $t])->count(),
            'training' => DB::table('messages')->where('user_id', $userId)->where('league_id', $club->league_id)->where('type', 'training_done')->whereBetween('created_at', [$f, $t])->count(),
            'unbeaten' => $results->count(), 'lost' => $results->filter(fn ($r) => $r === -1)->count(),
        ];
    }

    /** The big quest's club money: bp of the league's money scale. */
    private static function bigMoney(Club $club): int
    {
        return intdiv(Economy::scale($club->league_id) * (int) config('game.quests.unbeaten.money_bp'), 10000);
    }

    /** This week in Cairo: [Monday 00:00, next Monday 00:00]. */
    private static function week(): array
    {
        $from = GameClock::now()->setTimezone('Africa/Cairo')->startOfWeek(Carbon::MONDAY);

        return [$from, $from->copy()->addWeek()];
    }
}
