<?php

namespace App\Assistant;

use App\League\ClubAgenda;
use App\League\Standings;
use App\Models\Club;
use App\Models\League;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [X61 E11] Two answers the Assistant Coach gives from the club itself, at once and without the AI: «ماذا أفعل
 * الآن؟», the three most urgent things (what waits, by severity, then the lineup and the training), each with its
 * page; and the week's summary (the last seven days' results, the points and the place).
 */
class Priorities
{
    public const TOPICS = ['now', 'week'];

    private const GO = ['window' => 'match', 'lineup' => 'lineup', 'offers' => 'market', 'requests' => 'league', 'training_empty' => 'training', 'training_done' => 'training'];

    private const SAY = [
        'window' => ['النافذة التكتيكية مفتوحة في مباراتك الآن: غيّر ما تحتاجه قبل أن تُغلق.', 'Your match\'s tactical window is open now: change what you need before it closes.'],
        'lineup' => ['في تشكيلتك مصاب أو موقوف: بدّله قبل القفل.', 'An injured or suspended player is in your lineup: replace them before the lock.'],
        'offers' => ['عندك عروض واردة في السوق تنتظر ردك.', 'You have incoming offers in the market waiting for your answer.'],
        'requests' => ['مدربون طلبوا الانضمام لدوريك.', 'Coaches asked to join your league.'],
        'training_empty' => ['خانة تدريب فارغة: ضع فيها لاعباً، فكل جلسة تفوت.', 'A training slot is empty: put a player in it, every session counts.'],
        'training_done' => ['انتهى تدريب لاعب: اختر التالي.', 'A player finished training: pick the next one.'],
    ];

    /** The answer for a topic, or null without a club in that league. */
    public static function answer(string $topic, int $userId, ?int $leagueId, string $l): ?array
    {
        $league = $leagueId ? League::find($leagueId) : null;
        $club = $league ? Club::where('league_id', $league->id)->where('user_id', $userId)->first() : null;
        if (! $club) {
            return null;
        }

        return $topic === 'now' ? self::now($club, $league, $userId, $l) : self::week($club, $league, $l);
    }

    private static function now(Club $club, League $league, int $userId, string $l): array
    {
        $en = $l === 'en';
        $items = array_slice(ClubAgenda::pending($club, $league, $userId), 0, 3);
        $lines = array_map(fn ($p) => self::SAY[$p['kind']][$en ? 1 : 0] ?? null, $items);
        $lines = array_values(array_filter($lines));
        if (count($lines) < 3) {
            // Nothing urgent left: the usual good habits fill the three.
            foreach ($en ? ['Check your lineup and tactics for the next match.', 'Look at the market for a player who strengthens your weakest line.', 'Build the next part of your stadium.']
                : ['راجع تشكيلتك وتكتيكك للمباراة القادمة.', 'ابحث في السوق عن لاعب يقوّي أضعف خطوطك.', 'ابنِ الجزء التالي من ملعبك.'] as $habit) {
                if (count($lines) < 3) {
                    $lines[] = $habit;
                }
            }
        }
        $go = $items ? (self::GO[$items[0]['kind']] ?? null) : 'lineup';
        $text = ($en ? "Your three priorities now:\n" : "أولوياتك الثلاث الآن:\n").implode("\n", array_map(fn ($i, $t) => ($i + 1).'. '.$t, array_keys($lines), $lines));

        return ['answer' => $text, 'go' => $go];
    }

    private static function week(Club $club, League $league, string $l): array
    {
        $en = $l === 'en';
        $since = GameClock::now()->subDays(7);
        $games = DB::table('fixtures')->where('season_id', $league->season?->id)->where('status', 'finished')->where('is_bye', false)
            ->where('scheduled_at', '>=', $since)->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->get();
        $w = $d = $lo = $for = $against = 0;
        foreach ($games as $g) {
            [$f, $a] = $g->home_id === $club->id ? [(int) $g->home_goals, (int) $g->away_goals] : [(int) $g->away_goals, (int) $g->home_goals];
            $for += $f;
            $against += $a;
            $f > $a ? $w++ : ($f === $a ? $d++ : $lo++);
        }
        $place = $league->season ? array_search($club->id, Standings::order($league->season->id), true) : false;
        $where = $place === false ? '' : ($en ? ' You are '.($place + 1).' in the table.' : ' ومركزك الآن '.($place + 1).'.');
        $text = ! $games->count()
            ? ($en ? 'No match of yours finished this week.'.$where : 'لم تنتهِ لك مباراة هذا الأسبوع.'.$where)
            : ($en ? sprintf('This week: %d played, %d won, %d drawn, %d lost; goals %d for and %d against; %d points.', $games->count(), $w, $d, $lo, $for, $against, 3 * $w + $d).$where
                : sprintf('هذا الأسبوع: %d مباريات، فزت في %d وتعادلت في %d وخسرت %d؛ سجلت %d واستقبلت %d؛ %d نقطة.', $games->count(), $w, $d, $lo, $for, $against, 3 * $w + $d).$where);

        return ['answer' => $text, 'go' => 'stats'];
    }
}
