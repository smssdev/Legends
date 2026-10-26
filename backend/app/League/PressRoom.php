<?php

namespace App\League;

use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The press conference before a match [UP12, the owner's spec 6]: it opens game.press.open_minutes before kick-off
 * (until the lock), with the chances of each side and a reading of where each is strong and weak, and each coach
 * gives one of three statements, which lifts his team's morale in that match (Morale::forMatch). The reading uses
 * only what any coach can see: the strength and the lines of the eleven, never the tactics.
 */
class PressRoom
{
    public const STATEMENTS = [
        'attack' => 'سنلعب من أجل الفوز الكاسح ولن نتراجع للدفاع.',
        'calm' => 'نحترم قوة المنافس وسنلعب بتركيز تكتيكي وانضباط كامل.',
        'rally' => 'ثقتي في اللاعبين مطلقة وسنقاتل حتى آخر دقيقة لإسعاد جماهيرنا.',
    ];

    private const LINES = ['gk' => 'حراسة المرمى', 'def' => 'الدفاع', 'mid' => 'الوسط', 'att' => 'الهجوم'];

    /** The conference as one coach sees it. */
    public static function of(object $fixture, ?int $clubId): array
    {
        $home = Club::findOrFail($fixture->home_id);
        $away = Club::findOrFail($fixture->away_id);
        $kickoff = Carbon::parse($fixture->scheduled_at, 'UTC');
        $opens = $kickoff->copy()->subMinutes((int) config('game.press.open_minutes'));
        [$h, $a] = [self::lines($home), self::lines($away)];
        $said = DB::table('press_statements')->where('fixture_id', $fixture->id)->pluck('kind', 'club_id');

        return [
            'fixture_id' => $fixture->id,
            'opens_at' => $opens->toIso8601ZuluString(),
            'open' => self::open($fixture),
            'chances' => self::chances((int) $home->strength_snapshot, (int) $away->strength_snapshot),
            'reading' => ['home' => self::reading($h, $a), 'away' => self::reading($a, $h)],
            'lines' => ['home' => $h, 'away' => $a],
            'statements' => array_map(fn ($k, $t) => ['kind' => $k, 'text' => $t], array_keys(self::STATEMENTS), self::STATEMENTS),
            'said' => ['home' => $said[$home->id] ?? null, 'away' => $said[$away->id] ?? null],
            'mine' => $clubId === $home->id ? 'home' : ($clubId === $away->id ? 'away' : null),
            'morale' => (int) config('game.press.morale'),
        ];
    }

    /** The statements are given from the opening until the lock. */
    public static function open(object $fixture): bool
    {
        $now = GameClock::now();
        $kickoff = Carbon::parse($fixture->scheduled_at, 'UTC');

        return $fixture->status === 'scheduled' && $now->gte($kickoff->copy()->subMinutes((int) config('game.press.open_minutes'))) && $now->lt(MatchPrep::lockAt($fixture));
    }

    public static function say(object $fixture, int $clubId, string $kind): void
    {
        if (! array_key_exists($kind, self::STATEMENTS)) {
            throw new HttpException(422, 'اختر أحد التصريحات الثلاثة.');
        }
        if (! self::open($fixture)) {
            throw new HttpException(409, 'المؤتمر الصحفي يُعقد قبل المباراة بنصف ساعة حتى قفل التشكيلة.');
        }
        $new = DB::table('press_statements')->insertOrIgnore(['fixture_id' => $fixture->id, 'club_id' => $clubId, 'kind' => $kind, 'created_at' => GameClock::now()]);
        if ($new !== 1) {
            throw new HttpException(409, 'أدليت بتصريحك لهذه المباراة.');
        }
    }

    /** Each side's chance (per cent, adding up to 100), from the strength gap and the home ground. */
    public static function chances(int $homeCp, int $awayCp): array
    {
        $gap = ($homeCp - $awayCp) / 100 + 2.5;   // points of strength, the home ground worth about 2.5
        $home = 1 / (1 + 10 ** (-$gap / 12));
        $draw = max(0.18, 0.3 - abs($home - 0.5) * 0.25);
        $h = (int) round(($home * (1 - $draw)) * 100);
        $d = (int) round($draw * 100);

        return ['home' => $h, 'draw' => $d, 'away' => 100 - $h - $d];
    }

    /** The average rating of each line of the club's best eleven (what the opponent can see too). */
    private static function lines(Club $club): array
    {
        $eleven = TeamSheet::best($club);
        $squad = collect(TeamSheet::squad($club))->keyBy('id');
        $by = [];
        foreach ($eleven['starters'] as $i => $id) {
            if ($id !== null && isset($squad[$id])) {
                $by[$eleven['slots'][$i]['line']][] = (int) $squad[$id]['a']['ovr'];
            }
        }

        return array_map(fn ($line) => isset($by[$line]) ? intdiv(array_sum($by[$line]), count($by[$line])) : 0, array_combine(array_keys(self::LINES), array_keys(self::LINES)));
    }

    /** Where a side is ahead and behind its opponent, in a sentence. */
    private static function reading(array $mine, array $theirs): string
    {
        $gaps = [];
        foreach (self::LINES as $line => $name) {
            $gaps[$line] = $mine[$line] - $theirs[$line];
        }
        arsort($gaps);
        $best = array_key_first($gaps);
        $worst = array_key_last($gaps);
        $strong = $gaps[$best] > 0 ? 'يتفوق في '.self::LINES[$best].' (+'.$gaps[$best].')' : 'لا يتفوق في أي خط';
        $weak = $gaps[$worst] < 0 ? 'ويعاني في '.self::LINES[$worst].' ('.$gaps[$worst].')' : 'ولا نقطة ضعف واضحة';

        return "{$strong}، {$weak}.";
    }
}
