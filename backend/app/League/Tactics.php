<?php

namespace App\League;

use App\Engine\MatchSetup;
use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * A club's tactics [PLAN 2.14], in the engine's own keys. Tactics change how a match is played, never a
 * strength number [ENGINE 1, 5]. The tips explain those mechanisms in our own words and change nothing.
 * Only four tactics are ever shown to the opponent: tackling, marking, the plan and the offside trap
 * [PLAN 2.13]. Pressing, style, tempo, positions and the defensive shape never leave the server for him.
 */
class Tactics
{
    public const RULES = [
        'plan' => ['counter', 'long', 'passing', 'wings', 'shots'],
        'tackling' => [0, 3],
        'pressing' => [0, 100],
        'style' => [0, 100],
        'tempo' => [0, 100],
        'att' => ['back', 'support', 'only'],
        'mid' => ['def', 'stay', 'push'],
        'def' => ['stay', 'fullbacks', 'mid'],
        'trap' => [0, 1],
        'marking' => ['zone', 'man'],
    ];

    /** What the opponent may see once the sides are locked. */
    public const PUBLIC = ['tackling', 'marking', 'plan', 'trap'];

    public const REFEREES = ['lenient', 'medium', 'strict'];

    /** Mine, or the neutral defaults (a bot's, or a coach who never set any). */
    public static function of(Club $club): array
    {
        $row = DB::table('tactics')->where('club_id', $club->id)->first();
        if (! $row) {
            return MatchSetup::DEFAULT_TACTICS;
        }
        $t = [];
        foreach (array_keys(MatchSetup::DEFAULT_TACTICS) as $k) {
            $t[$k] = is_numeric($row->$k) ? (int) $row->$k : $row->$k;
        }

        return $t;
    }

    public static function save(Club $club, array $changes): array
    {
        MatchPrep::assertOpen($club);
        $t = array_merge(self::of($club), $changes);
        foreach (self::RULES as $key => $rule) {
            $v = $t[$key];
            $ok = is_int($rule[0]) ? is_int($v) && $v >= $rule[0] && $v <= $rule[1] : in_array($v, $rule, true);
            if (! $ok) {
                throw ValidationException::withMessages([$key => 'قيمة غير مسموحة لهذا الإعداد.']);
            }
        }
        $now = GameClock::now();
        DB::table('tactics')->upsert([['club_id' => $club->id] + $t + ['created_at' => $now, 'updated_at' => $now]], ['club_id'], array_merge(array_keys($t), ['updated_at']));

        return $t;
    }

    public static function public(array $t): array
    {
        return array_combine(self::PUBLIC, array_map(fn ($k) => $t[$k], self::PUBLIC));
    }

    /**
     * Tips in plain Arabic from the engine's own mechanisms [ENGINE 5, 6]. Context: the next referee and
     * whether the opponent's midfield is better, when known. A tip explains; it never changes a number.
     */
    public static function tips(array $t, ?string $referee = null): array
    {
        $tips = [];
        $hard = $t['tackling'] >= 2;
        if ($t['pressing'] >= 70 && $hard) {
            $tips[] = 'ضغط عالٍ مع قطع قوي: كرات مسترجعة أكثر، لكن كل صراع تخسره قد يصير خطأ'.($referee === 'strict' ? '، والحكم صارم: انتظر بطاقات.' : '.');
        } elseif ($t['tackling'] === 3) {
            $tips[] = 'الخشونة تكسب صراعات أكثر، لكنها تعني أخطاء وبطاقات أكثر'.($referee === 'strict' ? '، خصوصاً مع حكم صارم.' : '، وقد يُطرد لاعب.');
        }
        if ($t['pressing'] >= 75) {
            $tips[] = 'الضغط العالي يرهق لاعبيك أسرع: جهّز التبديلات بين الدقيقة 60 و70.';
        } elseif ($t['pressing'] <= 25) {
            $tips[] = 'ضغط منخفض: لياقة محفوظة، لكن الخصم يبني هجماته بهدوء.';
        }
        if ($t['tempo'] >= 75) {
            $tips[] = 'الإيقاع العالي يفتح المباراة للطرفين ويقلل دقة البناء، وهو خطر ضد وسط أمهر من وسطك.';
        }
        if ($t['style'] >= 75) {
            $tips[] = 'أسلوب هجومي: لاعبون أكثر في الهجمة، ومساحات خلفهم للمرتدات.';
        } elseif ($t['style'] <= 25) {
            $tips[] = 'أسلوب دفاعي: أهداف أقل عليك، وفرص أقل لك.';
        }
        $tips[] = match ($t['plan']) {
            'counter' => 'المرتد ينجح ضد خصم يدافع عالياً، ويتعثر ضد خصم متراجع.',
            'long' => 'الكرات الطويلة تتجاوز الضغط العالي، وتضيع كثيراً ضد دفاع منظم في الوسط.',
            'passing' => 'التمرير يتفوق على دفاع الوسط، ويتعب ضد الضغط العالي والدفاع المتراجع.',
            'wings' => 'الأجنحة تفتح الدفاع المتراجع، وتُقطع أسهل ضد الضغط العالي.',
            'shots' => 'التسديد من بعيد سلاح ضد الدفاع المتراجع، وأضعف ضد من يضغط عليك.',
        };
        if ($t['trap'] === 1) {
            $tips[] = 'مصيدة التسلل توقف الكرات الطويلة والمرتدات، لكن فشلها يترك الخصم وحده أمام المرمى.';
        }
        if ($t['marking'] === 'man') {
            $tips[] = 'رجل لرجل يحد من أخطر مهاجم للخصم، ويضعف أمام طريقة بثلاثة مهاجمين أو أكثر.';
        }
        if ($t['def'] === 'fullbacks') {
            $tips[] = 'هجوم الظهيرين يقوي الأجنحة، ويترك الأطراف خلفهما مكشوفة.';
        }

        return $tips;
    }
}
