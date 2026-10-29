<?php

namespace App\Support;

/**
 * The words of the game explained [X19]: one Arabic sentence or two for each training, stadium, staff and market term,
 * shown behind the "?" beside it. The tactics have their own (App\League\Tactics::HELP). The numbers come from
 * config/game.php, so the text never says other than the game does.
 */
class Glossary
{
    public static function all(): array
    {
        return self::of(app()->getLocale());
    }

    /** [Sprint 22] In one language, whatever the request's: the Assistant Coach's guide reads both. */
    public static function of(string $locale): array
    {
        return $locale === 'en' ? self::english() : self::arabic();
    }

    private static function arabic(): array
    {
        $t = config('game.training');
        $s = config('game.scout');
        $e = config('game.economy');

        return [
            'training' => sprintf('لاعب واحد من كل خط يتدرب، بشرط مدرب ذلك الخط في الجهاز الفني، وجلسة كل %d ساعات ولو كنت غائباً. حين يمتلئ شريطه إلى 100%% ترتفع قوته وخصائصه نقطة، وكلما كان أقوى احتاج جلسات أكثر. والعمر أقوى عامل: حتى 19 سنة كل جلسة أكبر بـ %d%%، ومن 29 تصغر حتى %d%% فقط بعد 32.', $t['tick_hours'], intdiv(reset($t['age_step_bp']), 100) - 100, intdiv(end($t['age_step_bp']), 100)),
            'potential' => 'الإمكانية: القوة التي يصلها اللاعب بالتدريب العادي. التدريب مفتوح، فيتجاوزها، لكن كل نقطة بعدها تأخذ جلسات أكثر بكثير، حتى 99.',
            'progress' => 'التقدم: شريط التدريب الحالي. كل جلسة تضيف إليه، وعند 100% نقطة قوة جديدة ويبدأ الشريط من جديد.',
            'stadium' => 'الملعب ثلاثة أقسام: المقاعد (دخل التذاكر)، وأرضية الملعب (أفضلية الأرض وتقليل الإصابات)، ومنشأة التدريب (تسرّع التدريب). كل قسم ثلاث مراحل، وكل مرحلة خمسة أجزاء تُبنى جزءاً جزءاً.',
            'seats' => 'المقاعد: سعة أكبر تبيع تذاكر أكثر في كل مباراة على أرضك بنفس السعر.',
            'pitch' => 'أرضية الملعب: كل مرحلة تزيد أفضلية فريقك في مباريات الأرض.',
            'training_ground' => 'منشأة التدريب: كل مرحلة تسرّع جلسات التدريب لكل لاعبيك.',
            'specialists' => sprintf('الجهاز الفني بعقود مؤقتة (%d أيام) ونجوم من 1 إلى 5: مدرب لكل خط يسرّع تدريب لاعبيه (ومدرب الحراس يرفع الحارس في المباراة أيضاً)، والمعالج البدني يسرّع استرجاع اللياقة، والطبيب يقصّر الإصابات، والمحامي يلغي جزءاً من إيقافات الطرد. نجوم أكثر، أثر أكبر وسعر أعلى، ويُجدَّد العقد في آخر يوم منه وإلا يستقيل صاحبه.', config('game.specialists.contract_days')),
            'scout' => sprintf('الكشاف: رحلة %d ساعة يبحث فيها عن لاعبين من خارج الدوري بمواصفاتك، ثم يعود بـ %d خيارات لا يشتريها غيرك حتى يتجدد السوق. وإن لم يجد أحداً يُرد لك المبلغ.', $s['hours'], $s['results']),
            'pool' => sprintf('مجموعة السوق: لاعبون من كل الدوريات بقوة دوريك، تتجدد كل %d ساعات. تشتري منها بقيمة اللاعب.', $e['pool_hours']),
            'quick_sale' => sprintf('البيع الفوري: يُباع اللاعب الآن بقيمته كاملة مقابل %d كوينز. وفي الدوري النزيه بخصم من قيمته بدل الكوينز.', config('game.premium.price.quick_sale')),
            'listing' => sprintf('العرض في السوق: تحدد السعر من نصف القيمة إلى السقف (%d%% منها، وقيمته فقط للاعب اشتريته)، وتعرض %d لاعبين على الأكثر في نفس الوقت. كلما اقترب السعر من القيمة بِيع أسرع، وعند السقف يأخذ نحو %d أيام، والشباب والجيدون يُطلبون أسرع من الكبار والضعاف، وفي النهاية يُباع دائماً. وما يدفعه المشترون من خارج الدوري فوق القيمة في الموسم له حد (%d%% من حجم أموال الدوري)، فإذا قارب الحد صغر السقف.', intdiv($e['sale_cap_bp'], 100), $e['max_listings'], intdiv(max($e['virtual_buyer']['hours_at_bp']), 24), intdiv($e['outside_premium_bp_per_season'], 100)),
            'value' => 'القيمة: سعر اللاعب من قوته وعمره ومركزه وإمكانيته. التدريب يرفعها فوراً.',
            'fitness' => sprintf('اللياقة: المباراة العادية تأخذ نحو 18%%، والضغط العالي والإيقاع السريع نحو 25%%. من 75%% فما فوق أداء كامل، ومن 55%% إلى 74%% أبطأ وتسديد أقل دقة، وتحت 55%% هبوط حاد واحتمال الإصابة ثلاثة أضعاف. من لعب يستعيد %d بعد المباراة، ومن ارتاح %d، فدوّر لاعبيك.', config('game.matches.played_recovery'), config('game.matches.rest_recovery')),
            'morale' => sprintf('المعنويات: الفوز يرفعها %d، والتعادل ينقصها %d والخسارة %d، وأكثر من ذلك مع كل مباراة أخرى بلا فوز. ومعنويات عالية تعني تقدماً وفرصاً أكثر في المباراة. جمهورك يضاعف دفعته على أرضك، وكل مدرب يشتري تذكرة لتشجيعك يزيدها. والمعد النفسي يعيد جزءاً منها بعد النتائج السيئة.', config('game.morale.win'), -config('game.morale.draw'), -config('game.morale.loss')),
            'chemistry' => sprintf('الكيمياء: كل لاعب مرتبط بأقرب زميلين له في التشكيلة. الرابط أخضر لنفس الجنسية من نفس النادي الأصلي أو بعد %d مباراة معاً، وأصفر لنفس الجنسية أو نفس الدوري السابق، وأحمر لغير ذلك. من 85 فما فوق تمرير ومرتدات وتغطية أفضل حتى 7%%، وتحت 50 أخطاء تمرير وسوء تفاهم في الدفاع.', config('game.chemistry.together_matches')),
        ];
    }

    /** [UP2] The same words in English, with the same numbers. */
    private static function english(): array
    {
        $t = config('game.training');
        $s = config('game.scout');
        $e = config('game.economy');

        return [
            'training' => sprintf('One player from each line trains, as long as that line\'s coach is in the technical staff, with a session every %d hours even while you are away. When their bar fills to 100%% their strength and attributes rise by a point, and the stronger they are the more sessions they need. Age is the strongest factor: up to 19 every session is %d%% bigger, and from 29 it shrinks, down to only %d%% after 32.', $t['tick_hours'], intdiv(reset($t['age_step_bp']), 100) - 100, intdiv(end($t['age_step_bp']), 100)),
            'potential' => 'Potential: the strength a player reaches with normal training. Training stays open, so they can pass it, but every point after it takes many more sessions, up to 99.',
            'progress' => 'Progress: the current training bar. Every session adds to it, and at 100% comes a new strength point and the bar starts again.',
            'stadium' => 'The stadium has three sections: the seats (ticket income), the pitch (home advantage and fewer injuries), and the training facility (faster training). Each section has three stages, and each stage five parts built one by one.',
            'seats' => 'Seats: a bigger capacity sells more tickets at every home match at the same price.',
            'pitch' => 'The pitch: every stage raises your team\'s advantage in home matches.',
            'training_ground' => 'The training facility: every stage speeds up the training sessions of all your players.',
            'specialists' => sprintf('The technical staff on temporary contracts (%d days) with 1 to 5 stars: a coach for each line speeds up its players\' training (and the goalkeeping coach also lifts the keeper in matches), the physio speeds up fitness recovery, the doctor shortens injuries, and the lawyer cancels part of red-card bans. More stars, a bigger effect and a higher price; the contract renews on its last day, or its holder resigns.', config('game.specialists.contract_days')),
            'scout' => sprintf('The scout: a %d-hour trip searching for players from outside the league to your specification, coming back with %d options no one else can buy until the market renews. If none are found, the amount is refunded.', $s['hours'], $s['results']),
            'pool' => sprintf('The market pool: players from every league at your league\'s strength, renewed every %d hours. You buy from it at the player\'s value.', $e['pool_hours']),
            'quick_sale' => sprintf('The instant sale: the player is sold now at their full value for %d coins. In a fair-play league, for a cut of the value instead of coins.', config('game.premium.price.quick_sale')),
            'listing' => sprintf('Listing on the market: you set the price from half the value up to the cap (%d%% of it, or the value alone for a player you bought), and you list at most %d players at a time. The closer the price to the value the faster it sells; at the cap it takes about %d days, the young and the good are wanted sooner than the old and the weak, and in the end it always sells. What buyers from outside the league pay above the value in a season has a limit (%d%% of the league\'s money scale), so near it the cap shrinks.', intdiv($e['sale_cap_bp'], 100), $e['max_listings'], intdiv(max($e['virtual_buyer']['hours_at_bp']), 24), intdiv($e['outside_premium_bp_per_season'], 100)),
            'value' => 'Value: the player\'s price from their strength, age, position and potential. Training raises it at once.',
            'fitness' => sprintf('Fitness: a normal match takes about 18%%, and high pressing with a fast tempo about 25%%. From 75%% up, full performance; from 55%% to 74%%, slower and less accurate shooting; below 55%%, a sharp drop and three times the injury risk. Players who played recover %d after the match and those who rested %d, so rotate your players.', config('game.matches.played_recovery'), config('game.matches.rest_recovery')),
            'morale' => sprintf('Morale: a win raises it by %d, a draw lowers it by %d and a loss by %d, and more with every further match without a win. High morale means more progress and more chances in matches. Your fans double their boost at home, and every coach who buys a ticket to back you adds to it. The sports psychologist restores part of it after bad results.', config('game.morale.win'), -config('game.morale.draw'), -config('game.morale.loss')),
            'chemistry' => sprintf('Chemistry: every player is linked to their two nearest teammates in the lineup. A link is green for the same nationality from the same original club or after %d matches together, yellow for the same nationality or the same former league, and red otherwise. From 85 up, better passing, counters and cover by up to 7%%; below 50, passing errors and misunderstandings in defence.', config('game.chemistry.together_matches')),
        ];
    }
}
