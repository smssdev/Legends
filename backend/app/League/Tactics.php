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

    /** [Sprint 38 E7] Five referees, from very lenient (green) to very strict (red). */
    public const REFEREES = ['very_lenient', 'lenient', 'medium', 'strict', 'very_strict'];

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
     * What each part of the tactics does, behind its "?" [X5, 2026-10-24]: for a coach new to the game. Written
     * from the engine's own mechanisms, like the tips; one place for the web and the app.
     */
    public const HELP = [
        'plan' => 'طريقة فريقك في الوصول للمرمى. المرتد: تنتظر وتنطلق بسرعة حين تسترجع الكرة، وينجح ضد من يهاجم بكثرة. الكرات الطويلة: تتجاوز الوسط وتنفع ضد الضغط العالي. التمريرات: بناء صبور يتفوق على من يدافع في الوسط. الأجنحة: اللعب على الأطراف والعرضيات، ويفتح الدفاع المتراجع. التسديد عن بعد: محاولات من خارج المنطقة ضد من يتكتل أمام مرماه. يراها الخصم بعد القفل.',
        'pressing' => 'كم يضغط لاعبوك على حامل الكرة. الضغط العالي يسترجع الكرة أسرع ويقطع بناء الخصم، لكنه يتعب لاعبيك أسرع ويزيد الأخطاء. والمنخفض يحفظ اللياقة ويترك الخصم يبني بهدوء. لا يراه الخصم.',
        'style' => 'كم لاعباً يشارك في الهجوم. الهجومي يصنع فرصاً أكثر لك، ويترك مساحات خلف لاعبيك للمرتدات. والدفاعي يقلل الأهداف عليك والفرص لك. لا يراه الخصم.',
        'tempo' => 'سرعة نقل الكرة. السريع يكثر الهجمات للطرفين ويقلل دقة التمرير، والهادئ يحفظ الكرة ويبطئ المباراة. وخطر الإيقاع السريع أكبر إذا كان وسط الخصم أمهر. لا يراه الخصم.',
        'tackling' => 'قوة التدخل على الخصم. القانوني: أخطاء قليلة لكن صراعات أقل. والحماس والخشونة: تكسب صراعات أكثر، ومعها أخطاء وبطاقات أكثر، وقد يُطرد لاعب، خصوصاً مع حكم صارم. يراه الخصم بعد القفل.',
        'lines' => 'ماذا يفعل كل خط حين يهاجم فريقك أو يدافع. الهجوم: «ارتداد» يرجع للمساعدة، و«مساندة الوسط» يربط اللعب، و«هجوم فقط» يبقى متقدماً للمرتدات. الوسط: «مساندة الدفاع» يحمي المرمى، و«بقاء» متوازن، و«اندفاع» يدخل منطقة الخصم. الدفاع: «بقاء» آمن، و«هجوم الظهيرين» يقوي الأجنحة ويكشف الأطراف، و«مساندة الوسط» يتقدم لاسترجاع الكرة. لا يراه الخصم.',
        'trap' => 'المدافعون يتقدمون معاً ليقع مهاجم الخصم في التسلل. توقف الكرات الطويلة والمرتدات، لكن إن فشلت بقي المهاجم وحده أمام حارسك. يراها الخصم بعد القفل.',
        'marking' => 'المنطقة: كل لاعب يحرس مساحته، وهي آمنة ضد أي طريقة. رجل لرجل: كل مدافع يلازم لاعباً، فيحد من أخطر مهاجم للخصم، ويضعف أمام ثلاثة مهاجمين أو أكثر. يراها الخصم بعد القفل.',
        'tips' => 'هذه نصائح من إعداداتك المحفوظة وحكم مباراتك القادمة: تشرح ما يحدث في المباراة ولا تغيّر أي رقم.',
    ];

    /** [UP2] The same help in English. */
    public const HELP_EN = [
        'plan' => 'How your team gets to goal. Counter-attack: wait and break fast when you win the ball back; works against teams that attack a lot. Long balls: skip the midfield; useful against high pressing. Passes: patient build-up that beats teams defending in midfield. Wings: play down the flanks with crosses; opens a deep defence. Long shots: efforts from outside the box against teams packed in front of goal. The opponent sees it after the lock.',
        'pressing' => 'How hard your players press the ball carrier. High pressing wins the ball back faster and cuts the opponent\'s build-up, but tires your players faster and adds fouls. Low pressing saves fitness and lets the opponent build calmly. The opponent does not see it.',
        'style' => 'How many players join the attack. Attacking makes more chances for you and leaves space behind your players for counters. Defensive cuts the goals against you and your chances. The opponent does not see it.',
        'tempo' => 'How fast the ball moves. Fast means more attacks for both sides and less accurate passing; calm keeps the ball and slows the match. A fast tempo is riskier if the opponent\'s midfield is more skilled. The opponent does not see it.',
        'tackling' => 'How hard you tackle. Legal: few fouls but fewer duels won. Keen and rough: more duels won, with more fouls and cards, and a player may be sent off, especially with a strict referee. The opponent sees it after the lock.',
        'lines' => 'What each line does when your team attacks or defends. Attack: «Drop back» comes back to help, «Support the midfield» links play, «Attack only» stays up for counters. Midfield: «Support the defence» protects the goal, «Stay» is balanced, «Push up» gets into the opponent\'s box. Defence: «Stay» is safe, «Full-backs attack» strengthens the wings and exposes the flanks, «Support the midfield» steps up to win the ball. The opponent does not see it.',
        'trap' => 'The defenders step up together to catch the opponent\'s forward offside. It stops long balls and counters, but if it fails the forward is alone in front of your keeper. The opponent sees it after the lock.',
        'marking' => 'Zonal: each player guards their space, safe against any formation. Man to man: each defender sticks to a player, limiting the opponent\'s most dangerous forward, and weaker against three forwards or more. The opponent sees it after the lock.',
        'tips' => 'These tips come from your saved settings and your next match\'s referee: they explain what happens in the match and change no number.',
    ];

    /**
     * Tips in plain Arabic from the engine's own mechanisms [ENGINE 5, 6]. Context: the next referee and
     * whether the opponent's midfield is better, when known. A tip explains; it never changes a number.
     */
    public static function tips(array $t, ?string $referee = null): array
    {
        $tips = [];
        $hard = $t['tackling'] >= 2;
        if ($t['pressing'] >= 70 && $hard) {
            $tips[] = 'ضغط عالٍ مع قطع قوي: كرات مسترجعة أكثر، لكن كل صراع تخسره قد يصير خطأ'.(in_array($referee, ['strict', 'very_strict'], true) ? '، والحكم صارم: انتظر بطاقات.' : '.');
        } elseif ($t['tackling'] === 3) {
            $tips[] = 'الخشونة تكسب صراعات أكثر، لكنها تعني أخطاء وبطاقات أكثر'.(in_array($referee, ['strict', 'very_strict'], true) ? '، خصوصاً مع حكم صارم.' : '، وقد يُطرد لاعب.');
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

        // [UP2] In English for an English request (lang/en.json).
        return array_map(fn (string $tip) => __($tip), $tips);
    }
}
