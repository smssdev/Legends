<?php

namespace App\Experience;

use App\League\Chemistry;
use App\League\ClubAgenda;
use App\League\Morale;
use App\League\TeamSheet;
use App\Models\Club;
use App\Season\CoachRating;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 64 W5 F5] Where a number on the screens comes from: the chemistry, the strength, the morale and the coach's
 * rating, each as its value and its parts (a label and a signed or plain value), with the guide's topic for more.
 * Only the coach's own club: nothing of a rival's, and no tactic.
 */
class Explain
{
    public const WHAT = ['chemistry', 'strength', 'morale', 'rating'];

    private const TIERS = ['prospect' => 'الواعد', 'tactician' => 'التكتيكي', 'professional' => 'المحترف', 'elite' => 'النخبة', 'mastermind' => 'العقل المدبر', 'icon' => 'الأيقونة', 'legend' => 'الأسطورة'];

    private const TIERS_EN = ['prospect' => 'Prospect', 'tactician' => 'Tactician', 'professional' => 'Professional', 'elite' => 'Elite', 'mastermind' => 'Mastermind', 'icon' => 'Icon', 'legend' => 'Legend'];

    private const TOPIC = ['chemistry' => 'chemistry', 'strength' => 'strength', 'morale' => 'morale', 'rating' => 'rating'];

    /** @return array{what: string, value: int, parts: list<array{label: string, value: string}>, topic: string} */
    public static function of(string $what, Club $club, int $userId): array
    {
        [$value, $parts] = match ($what) {
            'chemistry' => self::chemistry($club),
            'strength' => self::strength($club),
            'morale' => self::morale($club),
            'rating' => self::rating($userId),
        };

        return ['what' => $what, 'value' => $value, 'parts' => $parts, 'topic' => self::TOPIC[$what]];
    }

    private static function chemistry(Club $club): array
    {
        $sheet = TeamSheet::current($club);
        $c = Chemistry::of($club->id, $sheet['starters'], $sheet['slots']);
        $values = config('game.chemistry.link_value');
        $count = array_count_values(array_column($c['links'], 'color'));
        $labels = ['green' => __('روابط قوية (جنسية ونادٍ، أو مباريات معاً)'), 'yellow' => __('روابط متوسطة (جنسية أو دوري)'), 'red' => __('روابط ضعيفة')];
        $parts = [];
        foreach ($labels as $color => $label) {
            $parts[] = ['label' => $label, 'value' => sprintf('%d × %d', $count[$color] ?? 0, (int) $values[$color])];
        }

        return [(int) $c['score'], $parts];
    }

    private static function strength(Club $club): array
    {
        $sheet = TeamSheet::current($club);
        $ids = array_values(array_filter($sheet['starters']));
        $rows = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', $ids)
            ->get(['master_players.line', DB::raw('players.overall + players.training_bonus as overall')]);
        $names = ['gk' => __('الحارس'), 'def' => __('الدفاع'), 'mid' => __('الوسط'), 'att' => __('الهجوم')];
        $parts = [];
        foreach ($names as $line => $label) {
            $in = $rows->where('line', $line);
            $parts[] = ['label' => $label, 'value' => (string) ($in->isEmpty() ? 0 : intdiv((int) $in->sum('overall'), $in->count()))];
        }

        return [intdiv((int) $club->strength_snapshot, 100), $parts];
    }

    private static function morale(Club $club): array
    {
        $c = config('game.morale');
        $now = (int) $club->morale;
        $parts = [['label' => __('بداية الموسم'), 'value' => (string) $c['start']], ['label' => __('النتائج حتى الآن'), 'value' => sprintf('%+d', $now - (int) $c['start'])]];
        if ((int) $club->winless_run >= 2) {
            $parts[] = ['label' => __('مباريات بلا فوز'), 'value' => (string) $club->winless_run];
        }
        if ($f = ClubAgenda::nextFixture($club)) {
            $side = (int) $f->home_id === $club->id ? 'home' : 'away';
            $parts[] = ['label' => __('الجمهور والتذاكر والمؤتمر في المباراة القادمة'), 'value' => sprintf('%+d', Morale::forMatch($f, $side) - $now)];
        }

        return [$now, $parts];
    }

    private static function rating(int $userId): array
    {
        $r = CoachRating::of($userId);
        $en = app()->getLocale() === 'en';
        $tier = ($en ? self::TIERS_EN : self::TIERS)[$r['tier']['key']] ?? $r['tier']['key'];
        $parts = [['label' => __('الدرجة'), 'value' => $tier.($r['tier']['division'] ? ' '.['', 'I', 'II', 'III'][$r['tier']['division']] : '')], ['label' => __('أعلى نقاط بلغتها'), 'value' => (string) $r['peak']]];
        foreach (array_slice($r['recent'], 0, 5) as $c) {
            $parts[] = ['label' => $c['kind'] === 'match' ? sprintf('%s %d-%d %s', __(['win' => 'فوز', 'draw' => 'تعادل', 'loss' => 'خسارة'][$c['result']]), $c['for'], $c['against'], $c['opponent'])
                : __('لقب'), 'value' => sprintf('%+d', $c['delta'])];
        }

        return [(int) $r['points'], $parts];
    }
}
