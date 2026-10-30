<?php

namespace App\Assistant;

use App\League\Tactics;
use App\Support\Glossary;

/**
 * The game's guide [Sprint 22 B1]: every explanation the screens used to print (the "?" texts, the lines under the
 * titles, the paragraphs), and one for each part of the game, in Arabic and English. The Assistant Coach answers
 * from it, and the smart search (Search) finds in it when the AI cannot answer. The numbers come from
 * config/game.php (through Glossary for the terms it already had), so the guide never says other than the game does.
 *
 * A topic: its id, the pages it belongs to, the page its "open" button leads to, its question, the words a coach
 * may ask it with (colloquial ones too), and its answer.
 */
class Guide
{
    /** The pages the assistant knows, by the web's route names (others fall back to "home"). */
    public const PAGES = ['home', 'club', 'team', 'lineup', 'tactics', 'training', 'specialists', 'market', 'scout', 'stadium',
        'finance', 'quests', 'match', 'league', 'fixtures', 'stats', 'friendlies', 'newspaper', 'predictions', 'inbox', 'wallet',
        'profile', 'leagues', 'support', 'groups', 'tournaments'];

    /** A route of the web that is a page of another name here. */
    private const ALIASES = ['league-home' => 'league', 'league-newspaper' => 'newspaper', 'league-predictions' => 'predictions',
        'league-alliance' => 'league', 'league-draw' => 'league', 'create-league' => 'leagues', 'join' => 'leagues',
        'pick-team' => 'leagues', 'coach' => 'home', 'announcements' => 'home', 'league-report' => 'match',
        // [Sprint 27] The chat groups and the tournaments.
        'group' => 'groups', 'group-join' => 'groups', 'create-tournament' => 'tournaments', 'tournament' => 'tournaments', 'tournament-draw' => 'tournaments'];

    /** The pages an answer may open, by the web's section names. */
    public const GO = ['club', 'team', 'lineup', 'tactics', 'training', 'specialists', 'market', 'scout', 'stadium', 'finance',
        'quests', 'match', 'league', 'fixtures', 'stats', 'friendlies', 'newspaper', 'predictions', 'inbox', 'wallet', 'profile',
        'leagues', 'support', 'groups', 'tournaments'];

    /**
     * Each page's quick questions: a topic's id is answered from the guide at once; text after "?" goes to the
     * assistant to read the coach's own club.
     */
    private const QUICK = [
        'home' => ['rating', 'slots', 'leagues_create', 'leagues_join', 'coins', '?analysis_overview'],
        'club' => ['club_board', 'objectives', 'friendlies', 'quests', '?analysis_overview'],
        'team' => ['morale', 'fitness', 'value', 'potential', '?analysis_best'],
        'lineup' => ['lineup_edit', 'chemistry', 'takers', '?analysis_lineup'],
        'tactics' => ['pressing', 'marking', 'trap', 'opponent_sees', '?analysis_tactics'],
        'training' => ['training', 'basic_coach', 'potential', 'events', '?analysis_training'],
        'specialists' => ['specialists', '?analysis_specialists'],
        'market' => ['pool', 'listing', 'loans', 'academy', 'trades', '?analysis_sell'],
        'scout' => ['scout', 'value'],
        'stadium' => ['stadium', 'stadium_plan', 'seats', 'pitch', 'training_ground'],
        'finance' => ['finance', 'ticket_price', 'contracts', 'debt', '?analysis_money'],
        'quests' => ['quests', 'coins'],
        'match' => ['next_match', 'opponent_sees', 'spy', 'live_changes', 'integrity', '?analysis_last'],
        'league' => ['cup', 'invite', 'vacation_league', 'alliance', 'draw'],
        'fixtures' => ['stats', 'next_match'],
        'stats' => ['stats', 'awards', '?analysis_overview'],
        'friendlies' => ['friendlies'],
        'newspaper' => ['newspaper'],
        'predictions' => ['predictions'],
        'inbox' => ['inbox'],
        'wallet' => ['coins', 'referral', 'verification'],
        'profile' => ['verification', 'referral', 'vacation_account'],
        'leagues' => ['leagues_create', 'leagues_join', 'invite'],
        'support' => ['support'],
        'groups' => ['groups', 'league_group'],
        'tournaments' => ['tournaments', 'national_teams', 'tournament_draw'],
    ];

    public static function page(?string $route): string
    {
        $route = (string) $route;

        return in_array($route, self::PAGES, true) ? $route : (self::ALIASES[$route] ?? 'home');
    }

    /** Who the assistant is and what he does, opening every conversation. */
    public static function intro(string $l): string
    {
        return $l === 'en'
            ? "Hi coach! I'm Manager Bot, your assistant coach.\n• I explain any part of the game.\n• I read your club's numbers and analyse them: the lineup, fitness, results, training and money.\n• I advise you, and the decision is yours: I change nothing for you."
            : "أهلاً كوتش! أنا المدرب المساعد.\n• أشرح لك أي جزء في اللعبة.\n• أقرأ أرقام ناديك وأحللها: التشكيلة، واللياقة، والنتائج، والتدريب، والمالية.\n• أنصحك، والقرار لك: لا أغيّر شيئاً بدلاً منك.";
    }

    /** The quick questions of a page, each with what a tap sends: a topic's id, or a question for the assistant. */
    public static function quick(string $page, string $l): array
    {
        $topics = collect(self::topics($l))->keyBy('id');
        $asks = self::asks($l);

        return array_values(array_filter(array_map(function ($k) use ($topics, $asks) {
            if (str_starts_with($k, '?')) {
                return ['question' => $asks[substr($k, 1)], 'topic' => null];
            }

            return isset($topics[$k]) ? ['question' => $topics[$k]['q'], 'topic' => $k] : null;
        }, self::QUICK[self::page($page)] ?? self::QUICK['home'])));
    }

    public static function find(string $id, string $l): ?array
    {
        return collect(self::topics($l))->firstWhere('id', $id);
    }

    /** The whole guide as text: what the AI knows of the game's rules. */
    public static function text(string $l): string
    {
        return collect(self::topics($l))->map(fn ($t) => "## {$t['q']}\n{$t['a']}")->implode("\n\n");
    }

    /** The questions about the coach's own club, answered by the assistant from his numbers. */
    private static function asks(string $l): array
    {
        $ar = [
            'analysis_overview' => 'كيف حال فريقي الآن؟',
            'analysis_best' => 'مين أحسن لاعب عندي؟',
            'analysis_lineup' => 'هل تشكيلتي مناسبة للمباراة القادمة؟',
            'analysis_tactics' => 'أي تكتيك يناسب فريقي ضد خصمي القادم؟',
            'analysis_training' => 'مين أدرّبه الآن؟',
            'analysis_specialists' => 'أي أخصائي أحتاج أكثر؟',
            'analysis_sell' => 'أبيع مين؟',
            'analysis_money' => 'هل فلوسي تكفي لصفقة؟',
            'analysis_last' => 'ليش خسرت أو فزت آخر مباراة؟',
        ];
        $en = [
            'analysis_overview' => 'How is my team doing now?',
            'analysis_best' => 'Who is my best player?',
            'analysis_lineup' => 'Is my lineup right for the next match?',
            'analysis_tactics' => 'Which tactics suit my team against my next opponent?',
            'analysis_training' => 'Who should I train now?',
            'analysis_specialists' => 'Which specialist do I need most?',
            'analysis_sell' => 'Who should I sell?',
            'analysis_money' => 'Is my money enough for a signing?',
            'analysis_last' => 'Why did I win or lose my last match?',
        ];

        return $l === 'en' ? $en : $ar;
    }

    /** Every topic in one language. */
    /** [Sprint 25] The rating's rules, from game.rating, so the guide says what the game counts. */
    private static function rating(string $l): string
    {
        $w = config('game.rating');
        $en = $l === 'en';
        $names = $en ? ['prospect' => 'Prospect', 'tactician' => 'Tactician', 'professional' => 'Professional', 'elite' => 'Elite', 'mastermind' => 'Mastermind', 'icon' => 'Icon', 'legend' => 'Legend']
            : ['prospect' => 'الواعد', 'tactician' => 'التكتيكي', 'professional' => 'المحترف', 'elite' => 'النخبة', 'mastermind' => 'العقل المدبر', 'icon' => 'الأيقونة', 'legend' => 'الأسطورة'];
        $ladder = implode($en ? ', ' : '، ', array_map(fn ($k, $p) => $names[$k].' '.$p, array_keys($w['tiers']), $w['tiers']));
        $step = rtrim(rtrim(number_format($w['step_cp'] / 100, 2), '0'), '.');
        $t = $w['trophies'];

        return $en
            ? sprintf('Every league or cup match moves your points: a win %+d, a draw %+d and a loss %d against a side as strong as yours. For each %s points of strength the opponent was stronger (up to %d), a win earns %d more, a draw %d more and a loss costs %d less; against a weaker side the other way, so beating the strong pays and losing to the weak hurts. A win or draw away adds %d, and winning by %d goals or more %d. Trophies: the league title %d (second %d, third %d), the cup %d (finalist %d). The tiers by points: %s; each but the Legend in three divisions (III, II, I). A tier once reached is yours for good: a bad run costs points but never drops you below its start.',
                $w['win'], $w['draw'], $w['loss'], $step, $w['max_steps'], $w['per_step']['win'], $w['per_step']['draw'], $w['per_step']['loss'], $w['away'], $w['big_margin'], $w['big_win'],
                $t['league'][1], $t['league'][2], $t['league'][3], $t['cup'][1], $t['cup'][2], $ladder)
            : sprintf('كل مباراة دوري أو كأس تحرّك نقاطك: الفوز %+d، والتعادل %+d، والخسارة %d أمام فريق بقوة فريقك. ولكل %s نقطة قوة يزيدها الخصم عليك (حتى %d) يزيد الفوز %d، والتعادل %d، وتنقص الخسارة %d؛ وأمام الأضعف بالعكس، فالفوز على القوي يكافئك والخسارة أمام الضعيف تكلفك. والفوز أو التعادل خارج أرضك يضيف %d، والفوز بفارق %d أهداف أو أكثر %d. والألقاب: الدوري %d (الثاني %d، والثالث %d)، والكأس %d (الوصيف %d). والدرجات بالنقاط: %s؛ وكل درجة إلا الأسطورة بثلاثة مستويات (III، II، I). والدرجة التي تبلغها تبقى لك: السلسلة السيئة تنقص نقاطك ولا تنزلك تحت بدايتها.',
                $w['win'], $w['draw'], $w['loss'], $step, $w['max_steps'], $w['per_step']['win'], $w['per_step']['draw'], $w['per_step']['loss'], $w['away'], $w['big_margin'], $w['big_win'],
                $t['league'][1], $t['league'][2], $t['league'][3], $t['cup'][1], $t['cup'][2], $ladder);
    }

    public static function topics(string $l): array
    {
        $en = $l === 'en';
        $g = Glossary::of($l);
        $help = $en ? Tactics::HELP_EN : Tactics::HELP;
        $c = fn (string $key) => config("game.$key");
        $t = fn (string $id, array $pages, ?string $go, array $ar, array $english, ?string $answer = null) => [
            'id' => $id, 'pages' => $pages, 'go' => $go,
            'q' => $en ? $english[0] : $ar[0], 'words' => $en ? $english[1] : $ar[1],
            'a' => $answer ?? ($en ? $english[2] : $ar[2]),
        ];

        return [
            $t('about', self::PAGES, null,
                ['من أنت وماذا تفعل؟', 'مين انت مساعد بوت مانجر عرف نفسك وظيفتك تعمل ايه', ''],
                ['Who are you and what do you do?', 'who are you bot manager assistant help what do', ''],
                self::intro($l)),

            // The club and the coach's slots.
            $t('slots', ['home'], 'leagues',
                ['ما هي فتحات المدرب؟', 'فتحات فتحة اندية ثمانية اكثر من نادي فرقي مقفلة قفل فتح فوري', sprintf('لك %d فتحات: في كل واحدة نادٍ في دوري. يُفتح منها %d مع الحساب، وواحدة أخرى كل %d أيام من عمر حسابك، والعدّاد على كل فتحة مقفلة. أو افتح أول فتحة مقفلة فوراً بالكوينز (%s)، بالترتيب، وتبقى مفتوحة دائماً. اضغط فتحة ناديك لتدخلها، أو فتحة فارغة لتنضم إلى دوري أو تنشئ دوريك.', $c('league.max_active_teams'), $c('league.slots.open'), $c('league.slots.every_days'), implode('، ', array_map(fn ($n, $p) => "الفتحة {$n} بـ {$p}", array_keys($c('league.slots.unlock_coins')), $c('league.slots.unlock_coins'))))],
                ['What are the coach slots?', 'slots slot clubs eight many teams locked unlock instant', sprintf('You have %d slots: each holds a club in a league. %d are open with the account, and one more every %d days of your account\'s age, with a countdown on each locked slot. Or open the first locked slot now for coins (%s), in order, and it stays open for good. Tap your club\'s slot to go in, or an empty slot to join a league or create your own.', $c('league.max_active_teams'), $c('league.slots.open'), $c('league.slots.every_days'), implode(', ', array_map(fn ($n, $p) => "slot {$n} for {$p}", array_keys($c('league.slots.unlock_coins')), $c('league.slots.unlock_coins'))))]),
            // [Sprint 25] The coach's rating and its tiers.
            $t('rating', ['home'], null,
                ['كيف تُحسب نقاط المدرب ودرجاته؟', 'نقاط النقاط تصنيف درجة درجات رتبة رتب ترتيب تقييم المدرب اسطورة نخبة محترف تزيد تنقص خسارة فوز تعادل', self::rating('ar')],
                ['How do the coach points and tiers work?', 'points rating rank tier tiers division legend elite professional win draw loss lose', self::rating('en')]),
            $t('club_board', ['club'], 'club',
                ['ما هي لوحة النادي؟', 'لوحة النادي الرئيسية كروت بطاقات جائزة الجولة رجل الجولة', 'لوحة النادي أول صفحة لناديك: المباراة القادمة وعدّادها، وترتيبك، والتدريب والملعب الجاريان، وما ينتظرك. وفيها الوديات (مباراة الآن بلا أثر على الجدول تزيد تدريب لاعبيك)، والمهام الأسبوعية (كوينز لكل مهمة، وأموال للنادي في الكبرى)، وجوائز الجولة (رجل الجولة وأفضل مدرب وأفضل المباريات).'],
                ['What is the club board?', 'club board home cards awards man of the round', 'The club board is your club\'s first page: the next match and its countdown, your position, the training and stadium in progress, and what waits for you. On it are the friendlies (a match now with no effect on the table that adds to your players\' training), the weekly quests (coins for each quest, and money for the club in the big one), and the round\'s awards (man of the round, best coach and the best matches).']),
            $t('objectives', ['club'], 'club',
                ['ما هو هدف النادي؟', 'هدف النادي الادارة المطلوب مني المجلس اقالة', 'إدارة النادي تحدد لك هدفاً أول الموسم من قوة ناديك بين أندية دوريك: الأقوى يُطلب منه اللقب، وربع القمة مركزاً قريباً من ترتيب قوته، والباقون أبعد قليلاً، ولا يُطلب من أحد أقل من البقاء خارج المؤخرة. تحقيقه يمنحك كوينز في آخر الموسم.'],
                ['What is the club objective?', 'objective board target goal season', 'The board sets you an objective at the start of the season from your club\'s strength among its league: the strongest is asked for the title, the top quarter for a place near its strength rank, the others a little further, and nobody for less than staying out of the bottom. Reaching it earns you coins at the end of the season.']),
            $t('friendlies', ['club', 'friendlies'], 'friendlies',
                ['ما هي المباريات الودية؟', 'ودية وديات ودي تجريبية', sprintf('الودية مباراة الآن تُحاكى كاملة في ثوانٍ، بلا أثر على جدول الدوري وترتيبه ولا على المال: تجرّب بها تكتيكك وتجهّز لاعبيك. كل من يلعب يكسب %d لياقة، و%s%% من تدريبه، وتُحسب مباراة معاً في الانسجام. ثمنها %d كوينز تُخصم حين تؤكد بدء الودية، بلا حد.', $c('friendlies.fitness'), rtrim(rtrim(number_format($c('friendlies.training_progress') / 100, 2), '0'), '.'), $c('friendlies.coins'))],
                ['What are friendlies?', 'friendly friendlies test match', sprintf('A friendly is a match now, played whole in seconds, with no effect on the league table or the money: you try your tactics and get your players ready. Everyone who plays gains %d fitness and %s%% of their training, and it counts as a match together for the chemistry. It costs %d coins, taken when you confirm it, with no limit.', $c('friendlies.fitness'), rtrim(rtrim(number_format($c('friendlies.training_progress') / 100, 2), '0'), '.'), $c('friendlies.coins'))]),
            $t('quests', ['club', 'quests'], 'quests',
                ['ما هي المهام الأسبوعية؟', 'مهام مهمة اسبوعية تحديات كوينز', sprintf('كل أسبوع (من الاثنين للاثنين بتوقيت القاهرة) مهام: ودية (%d كوينز)، وفوزان (%d)، وجزء ملعب (%d)، وجلسة تدريب (%d). والكبرى: مباراتان بلا هزيمة، وجائزتها أموال لناديك. تستلم كل جائزة من صفحة المهام.', $c('quests.friendly.coins'), $c('quests.wins.coins'), $c('quests.stadium.coins'), $c('quests.training.coins'))],
                ['What are the weekly quests?', 'quests quest weekly challenges', sprintf('Each week (Monday to Monday, Cairo time) there are quests: a friendly (%d coins), two wins (%d), a stadium part (%d) and a training session (%d). The big one: two matches unbeaten, rewarded with money for your club. Claim each reward on the quests page.', $c('quests.friendly.coins'), $c('quests.wins.coins'), $c('quests.stadium.coins'), $c('quests.training.coins'))]),

            // The squad.
            $t('morale', ['team', 'match'], 'team', ['ما هي المعنويات؟', 'معنويات معنوية الروح نفسية', $g['morale']], ['What is morale?', 'morale spirit mood', $g['morale']]),
            $t('fitness', ['team', 'lineup'], 'team', ['ما هي اللياقة؟', 'لياقة تعب مرهق مجهد طاقة', $g['fitness']], ['What is fitness?', 'fitness tired energy stamina', $g['fitness']]),
            $t('value', ['team', 'market', 'scout'], 'market', ['ما هي قيمة اللاعب؟', 'قيمة سعر اللاعب ثمن', $g['value']], ['What is a player\'s value?', 'value price worth', $g['value']]),
            $t('potential', ['team', 'training'], 'training', ['ما هي الإمكانية؟', 'امكانية الامكانية سقف اللاعب تطور', $g['potential']], ['What is potential?', 'potential ceiling growth', $g['potential']]),
            $t('progress', ['training'], 'training', ['ما هو شريط التقدم؟', 'تقدم الشريط النسبة', $g['progress']], ['What is the progress bar?', 'progress bar percent', $g['progress']]),
            $t('chemistry', ['lineup'], 'lineup', ['ما هي الكيمياء؟', 'كيمياء الكيميا الروابط انسجام تفاهم', $g['chemistry']], ['What is chemistry?', 'chemistry links understanding', $g['chemistry']]),
            $t('lineup_edit', ['lineup'], 'lineup',
                ['كيف أعدّل التشكيلة؟', 'تشكيلة تشكيله تعديل اسحب تبديل الاحتياط ابدل لاعب', 'التشكيلة مقفلة حتى تضغط «تعديل». بعدها اسحب أي لاعب أساسي إلى أي مكان داخل منطقة خطه ليقف فيه، أو على لاعب آخر من نفس الخط ليتبادلا، أو بدّله بالاحتياط وبباقي الفريق، ثم اضغط «حفظ». وبعد الحفظ تُحسب الكيمياء وروابطها من جديد.'],
                ['How do I edit the lineup?', 'lineup edit drag swap bench substitute', 'The lineup is locked until you tap «Edit». Then drag any starter anywhere inside their line\'s area to place them, or onto another player of the same line to swap them, or swap them with the bench and the rest of the squad, then tap «Save». After saving, the chemistry and its links are worked out again.']),
            $t('takers', ['lineup'], 'lineup',
                ['من ينفذ الكرات الثابتة؟', 'منفذ ركلات جزاء ضربة حرة ركنية كورنر كابتن ثابتة', 'المنفذون من الأساسيين المحفوظين: ركلات الجزاء والحرة والركنيات. «تلقائي» يختار الأنسب، ولو خرج المنفذ من الملعب يختار المحرك بديله.'],
                ['Who takes the set pieces?', 'takers penalty free kick corner set piece captain', 'The takers come from the saved starters: penalties, free kicks and corners. «Auto» picks the best fit, and if the taker leaves the pitch the engine picks a replacement.']),

            // Tactics.
            $t('plan', ['tactics'], 'tactics', ['ما هي خطة اللعب؟', 'خطة اللعب مرتد مرتدات كرات طويلة تمريرات اجنحة تسديد بعيد', $help['plan']], ['What is the game plan?', 'plan counter long balls passes wings long shots', $help['plan']]),
            $t('pressing', ['tactics'], 'tactics', ['ماذا يفعل الضغط؟', 'ضغط عالي الضغط العالي منخفض بريس', $help['pressing']], ['What does pressing do?', 'pressing press high low', $help['pressing']]),
            $t('style', ['tactics'], 'tactics', ['ما هو أسلوب اللعب؟', 'اسلوب هجومي دفاعي متوازن', $help['style']], ['What is the style?', 'style attacking defensive balanced', $help['style']]),
            $t('tempo', ['tactics'], 'tactics', ['ما هو الإيقاع؟', 'ايقاع سريع هادئ بطيء سرعة', $help['tempo']], ['What is the tempo?', 'tempo fast slow calm', $help['tempo']]),
            $t('tackling', ['tactics'], 'tactics', ['ما هو قطع الكرة؟', 'قطع الكرة التدخل خشونة عنف حماس قانوني', $help['tackling']], ['What is tackling?', 'tackling tackle rough keen legal', $help['tackling']]),
            $t('lines', ['tactics'], 'tactics', ['ما هو التمركز؟', 'تمركز الخطوط ارتداد مساندة', $help['lines']], ['What is positioning?', 'positioning lines drop back support', $help['lines']]),
            $t('trap', ['tactics'], 'tactics', ['ما هي مصيدة التسلل؟', 'مصيدة المصيده تسلل اوفسايد', $help['trap']], ['What is the offside trap?', 'offside trap', $help['trap']]),
            $t('marking', ['tactics'], 'tactics', ['الرقابة: فردية أم منطقة؟', 'رقابة فردية رجل لرجل منطقة', $help['marking']], ['Marking: man to man or zonal?', 'marking man zonal zone', $help['marking']]),
            $t('tips', ['tactics'], 'tactics', ['ما هو الأثر المتوقع؟', 'الاثر المتوقع نصائح', $help['tips']], ['What is the expected effect?', 'expected effect tips', $help['tips']]),
            $t('opponent_sees', ['tactics', 'match'], 'tactics',
                ['ماذا يرى خصمي من تكتيكي؟', 'الخصم يشوف يرى سر خصوصية مخفي يعرف', 'خصمك يرى بعد القفل: الأحد عشر والطريقة وأربعة تكتيكات علنية فقط: قطع الكرة، والرقابة، وخطة اللعب، والمصيدة. أما الضغط والأسلوب والإيقاع والتمركز والشكل الدفاعي فلا يراها أحد غيرك. وكذلك أنت: خطة خصمك تظهر لك بعد القفل، وشكله الدفاعي لا يظهر، فاقرأه من مبارياته.'],
                ['What does my opponent see of my tactics?', 'opponent see secret private hidden know', 'After the lock your opponent sees the eleven, the formation and four public tactics only: tackling, marking, the game plan and the trap. Pressing, style, tempo, positioning and the defensive shape are seen by nobody but you. The same for you: your opponent\'s plan shows after the lock, and their defensive shape does not, so read it from their matches.']),
            $t('defensive_shape', ['tactics'], 'tactics',
                ['ما هو الشكل الدفاعي؟', 'الشكل الدفاعي الدفاع', 'الشكل الدفاعي يصنعه الضغط والأسلوب ومصيدة التسلل وتمركز الخطوط. ولا يراه خصمك أبداً.'],
                ['What is the defensive shape?', 'defensive shape defence', 'The defensive shape is made by the pressing, the style, the offside trap and the lines\' positioning. Your opponent never sees it.']),
            $t('scenarios', ['tactics', 'match'], 'tactics',
                ['ما هي السيناريوهات؟', 'سيناريو سيناريوهات خطط تلقائية لو متقدم متأخر', 'السيناريوهات خطط تُنفَّذ وحدها في لحظتها، مثل «لو تقدمنا بعد الدقيقة 70 نرجع للدفاع»، حتى لو لم تكن تتابع المباراة. لا يراها الخصم.'],
                ['What are scenarios?', 'scenario scenarios automatic plans ahead behind', 'Scenarios are plans carried out on their own at their moment, such as «if we lead after minute 70, drop back», even if you are not watching. The opponent does not see them.']),

            // Training and the staff.
            $t('training', ['training'], 'training', ['كيف يعمل التدريب؟', 'تدريب تمرين جلسة جلسات تطوير اللاعبين', $g['training']], ['How does training work?', 'training train session develop', $g['training']]),
            $t('ads', ['training', 'stadium'], 'training',
                ['هل الإعلان يسرّع التدريب؟', 'اعلان اعلانات فيديو تسريع تقليل الوقت', sprintf('نعم: كل إعلان تشاهده للنهاية يقلّص %d دقيقة من التدريب أو جزء الملعب، وحتى %d إعلانات للمهمة الواحدة.', $c('ads.minutes_per_video'), $c('ads.max_per_item'))],
                ['Does an ad speed up training?', 'ad ads video speed up time', sprintf('Yes: every ad watched to the end cuts %d minutes from the training or the stadium part, up to %d ads per task.', $c('ads.minutes_per_video'), $c('ads.max_per_item'))]),
            $t('specialists', ['specialists'], 'specialists', ['ما هو الجهاز الفني؟', 'جهاز فني اخصائي اخصائيين مدرب طبيب معالج محامي نجوم عقد', $g['specialists']], ['What is the technical staff?', 'staff specialist specialists coach doctor physio lawyer stars contract', $g['specialists']]),

            // The market and the scout.
            $t('pool', ['market'], 'market', ['ما هي مجموعة السوق؟', 'السوق مجموعة شراء اشتري لاعب جديد', $g['pool']], ['What is the market pool?', 'market pool buy player new', $g['pool']]),
            $t('quick_sale', ['market'], 'market', ['ما هو البيع الفوري؟', 'بيع فوري سريع بيع الان', $g['quick_sale']], ['What is the instant sale?', 'instant quick sale sell now', $g['quick_sale']]),
            $t('listing', ['market'], 'market', ['كيف أعرض لاعباً للبيع؟', 'عرض للبيع بيع لاعب ابيع سعر سقف', $g['listing'].($en ? ' If no coach buys them, a club from outside the league does, and the higher the price the longer the wait. Training raises a player\'s value and price.' : ' ولو لم يشتره مدرب يشتريه نادٍ من خارج الدوري، وكلما ارتفع السعر طال الانتظار. والتدريب يرفع قيمة اللاعب وسعره.')],
                ['How do I list a player for sale?', 'list sell player price cap', $g['listing'].' If no coach buys them, a club from outside the league does, and the higher the price the longer the wait. Training raises a player\'s value and price.']),
            // [Sprint 23] The admin's timed events.
            $t('events', ['market', 'training'], 'market',
                ['ما هي الفعاليات؟', 'فعالية فعاليات جنون الانتقالات التقدم الفائق خصم عروض خاصة نجوم الاسبوع اساطير', 'الفعاليات مؤقتة يعلنها مطورو اللعبة لوقت محدد، وتظهر في السوق والتدريب بعدّاد حتى نهايتها: جنون الانتقالات (المشترون من خارج الدوري وتجديد السوق أسرع)، والتقدم الفائق (كل جلسة تدريب أكبر)، وخصم السوق (لاعبو المجموعة أرخص)، والعروض الخاصة (لاعبون بخصم حتى تجديد السوق)، ونجوم الأسبوع (لاعبون في قمة مستواهم بنقاط زائدة تبقى معهم)، والأساطير (لاعبون أقوى من أفضل لاعبي دوريك بسعر أعلى).'],
                ['What are events?', 'event events transfer madness extreme progression discount special offers players of the week legends', 'Events are temporary, announced by the game\'s developers for a set time, and shown on the market and training with a countdown to their end: transfer madness (outside buyers and the market\'s renewal are faster), extreme progression (every training session is bigger), the market discount (the pool\'s players are cheaper), special offers (players at a discount until the market renews), players of the week (players in top form with extra points that stay with them) and legends (players stronger than your league\'s best, at a higher price).']),
            $t('trades', ['market'], 'market',
                ['كيف أشتري من مدرب آخر؟', 'عرض مدرب اخر شراء من مدرب تبادل مقايضة صفقة', 'لاعب معروض من مدرب: ترسل عرضاً بسعره، فيقبله مدربه أو يرده أو يرد بعرض مقابل. والسعر من نصف القيمة إلى سقف اللاعب. وفي التبادل تطلب لاعبين وتعطي غيرهم: المسموح أن تعطي من 50% إلى 200% من قيمة ما تطلب.'],
                ['How do I buy from another coach?', 'offer coach buy from swap exchange deal', 'A player listed by a coach: you send an offer at its price, and their coach accepts, rejects or counters. The price is from half the value up to the player\'s cap. In a swap you ask for players and give others: you may give from 50% to 200% of the value of what you ask for.']),
            $t('scout', ['scout'], 'scout', ['ما هو الكشاف؟', 'كشاف الكشافة استكشاف بحث عن لاعب', $g['scout']], ['What is the scout?', 'scout scouting search player', $g['scout']]),

            // The stadium.
            $t('stadium', ['stadium'], 'stadium', ['كيف يعمل الملعب؟', 'ملعب استاد توسيع بناء مراحل اجزاء', $g['stadium']], ['How does the stadium work?', 'stadium build expand stages parts', $g['stadium']]),
            $t('stadium_plan', ['stadium'], 'stadium',
                ['كم يأخذ بناء الملعب؟', 'وقت مدة بناء الملعب ساعة جزء', sprintf('تبني جزءاً واحداً في كل مرة، وكل جزء %d ساعة، وتبدأ كل جزء بنفسك. الملعب كاملاً %d جزءاً، أي معظم الموسم، فاختر أولوياتك: الدخل (المقاعد)، أو ميزة الأرض (الأرضية)، أو سرعة التدريب (المنشأة).', $c('stadium.part_hours'), $c('stadium.stages') * $c('stadium.parts_per_stage') * count($c('stadium.sections')))],
                ['How long does the stadium take?', 'time build stadium hours part', sprintf('You build one part at a time, each part takes %d hours, and you start each part yourself. The full stadium is %d parts, most of the season, so choose your priorities: income (seats), home advantage (pitch) or training speed (facility).', $c('stadium.part_hours'), $c('stadium.stages') * $c('stadium.parts_per_stage') * count($c('stadium.sections')))]),
            $t('seats', ['stadium'], 'stadium', ['ما فائدة المقاعد؟', 'مقاعد مدرجات تذاكر جمهور سعة', $g['seats']], ['What do the seats do?', 'seats stands tickets capacity', $g['seats']]),
            $t('pitch', ['stadium'], 'stadium', ['ما فائدة أرضية الملعب؟', 'ارضية الملعب العشب ميزة الارض', $g['pitch']], ['What does the pitch do?', 'pitch grass home advantage', $g['pitch']]),
            $t('training_ground', ['stadium'], 'stadium', ['ما فائدة منشأة التدريب؟', 'منشاة التدريب مركز', $g['training_ground']], ['What does the training facility do?', 'training facility ground', $g['training_ground']]),

            // Money.
            $t('finance', ['finance'], 'finance',
                ['كيف تعمل أموال النادي؟', 'فلوس اموال المالية دخل مصاريف رصيد رواتب', 'أموال النادي خاصة بهذا الدوري وتُصفّر مع الموسم الجديد. تدخل من تذاكر مباريات الأرض (تزيد بالمقاعد)، والرعاة، وجوائز الترتيب، وبيع اللاعبين. وتخرج في الرواتب كل جولة، والصفقات، والتدريب، والملعب، والجهاز الفني. وهي غير الكوينز: لا تتحول إحداهما للأخرى.'],
                ['How does the club\'s money work?', 'money finance income costs balance wages', 'The club\'s money belongs to this league and resets with the new season. It comes from home match tickets (more with seats), sponsors, prize money and player sales. It goes on wages every round, signings, training, the stadium and the staff. It is not coins: neither turns into the other.']),
            $t('sponsors', ['finance'], 'finance',
                ['كيف أختار الراعي؟', 'راعي رعاة رعاية عقد', 'تختار راعياً لكل قطاع أول الموسم، والعقد للموسم كله ولا يُغيَّر، فقارن العروض قبل التوقيع.'],
                ['How do I pick a sponsor?', 'sponsor sponsors contract', 'You pick a sponsor for each sector at the start of the season; the contract lasts the whole season and cannot change, so compare the offers before signing.']),
            $t('debt', ['finance'], 'finance',
                ['ماذا يحدث لو صار رصيدي بالسالب؟', 'سالب دين ديون عجز افلاس', sprintf('لو نزل الرصيد تحت الصفر بسبب الرواتب يُمنع أي صرف. وبعد %d جولات متتالية بالسالب يُباع أغلى لاعب تلقائياً للمجموعة بـ 70%% من قيمته.', $c('economy.debt_rounds_before_forced_sale'))],
                ['What happens if my balance goes negative?', 'negative debt broke', sprintf('If wages take the balance below zero, all spending stops. After %d rounds in a row below zero, your most valuable player is sold automatically to the pool at 70%% of their value.', $c('economy.debt_rounds_before_forced_sale'))]),
            $t('coins', ['wallet', 'home', 'quests'], 'wallet',
                ['ما هي الكوينز؟', 'كوينز كوين عملات ذهب نقاط شراء', sprintf('الكوينز عملتك أنت لا عملة النادي، وتُكسب داخل اللعبة فقط: الدخول اليومي (%d)، والفوز (%d)، والتعادل (%d)، وتحقيق الأهداف، والألقاب، والمهام. تنهي بها الانتظار وتشتري بها مزايا مثل الجاسوس، ولا تتحول أبداً إلى أموال نادٍ. والشراء الحقيقي بعد النسخة الأولى، فالآن الكل متساوٍ.', $c('premium.earn.daily'), $c('premium.earn.win'), $c('premium.earn.draw'))],
                ['What are coins?', 'coins coin gold currency buy', sprintf('Coins are your own currency, not the club\'s, earned only in the game: the daily login (%d), a win (%d), a draw (%d), reaching objectives, titles and quests. They end waits and buy features like the spy, and never turn into club money. Real purchases come after the first version, so for now everyone is equal.', $c('premium.earn.daily'), $c('premium.earn.win'), $c('premium.earn.draw'))]),

            // The match.
            $t('next_match', ['match', 'fixtures'], 'match',
                ['متى تُقفل المباراة؟', 'القفل قفل موعد المباراة الحكم صارم جاهز', 'الحكم وصرامته يُعلنان قبل المباراة بنصف ساعة، والتشكيلة والتكتيك يُقفلان قبلها بخمس دقائق (والمصاب والموقوف يُصحَّحان تلقائياً). وإن غبت يدير المدرب المساعد فريقك.'],
                ['When does the match lock?', 'lock time match referee strict ready', 'The referee and their strictness are announced half an hour before the match, and the lineup and tactics lock five minutes before it (the injured and suspended are fixed automatically). If you are away, the assistant coach runs your team.']),
            $t('live_changes', ['match'], 'match',
                ['متى أغيّر أثناء المباراة؟', 'تغيير تبديل اثناء المباراة مباشر توقف', 'في المباراة المباشرة تغيّر في فترات التوقف فقط: الدقائق 15 و30 و60 و75 والاستراحة. لك 3 تبديلات (وواحد إضافي في الوقت الإضافي). والمساعد يكتب لك ملاحظة كل ربع ساعة تقريباً، وبعد كل لحظة كبيرة.'],
                ['When can I make changes during a match?', 'change sub live during stoppage', 'In a live match you make changes in the stoppages only: minutes 15, 30, 60, 75 and half-time. You have 3 substitutions (plus one in extra time). Your assistant writes you a note about every quarter of an hour, and after every big moment.']),
            $t('spy', ['match'], 'match',
                ['ماذا يفعل الجاسوس؟', 'جاسوس تجسس اعرف خطة الخصم', 'الجاسوس يعرّفك خطة خصمك وتشكيلته وتكتيكه العلني وفورمته ولياقة أساسييه الآن، قبل القفل، مقابل مبلغ من أموال النادي. ولا يعرف خصمك أنك تجسست عليه. وما لا يكشفه أي جاسوس: ضغطه وأسلوبه وإيقاعه وتمركزه وشكله الدفاعي.'],
                ['What does the spy do?', 'spy spying opponent plan', 'The spy shows you your opponent\'s plan, lineup, public tactics, form and their starters\' fitness now, before the lock, for some of the club\'s money. Your opponent does not know you spied on them. What no spy reveals: their pressing, style, tempo, positioning and defensive shape.']),
            $t('integrity', ['match'], 'match',
                ['ما هي منظومة النزاهة؟', 'نزاهة رشوة الحكم فار جواسيس فحص امني محامي لجنة الانضباط', sprintf('في الدوري الذي يفعّلها: كل شيء له ثمن ومخاطرة. الرشوة تجعل الحكم يميل لك (بطاقات أقل لك وأكثر لخصمك، وركلات جزاء أسهل)، لكن الفار يكشف %d%% من المحاولات: يضيع المبلغ وتهبط المعنويات، وجاسوس الخصم قد يكتشفها ويرفع الأمر للجنة الانضباط. ومحامٍ بـ %d نجوم فأكثر يكشف الجواسيس عليك، أو فحص أمني للمباراة.', intdiv($c('integrity.var_bp'), 100), $c('integrity.lawyer_stars'))],
                ['What is the integrity system?', 'integrity bribe referee var spies security lawyer discipline', sprintf('In a league that turns it on, everything has a price and a risk. A bribe tilts the referee your way (fewer cards for you, more for your opponent, easier penalties), but VAR catches %d%% of attempts: the money is lost and morale drops, and the opponent\'s spy may find it and report it to the disciplinary committee. A lawyer with %d stars or more uncovers spies on you, or a security check for the match.', intdiv($c('integrity.var_bp'), 100), $c('integrity.lawyer_stars'))]),
            $t('press', ['match'], 'match',
                ['ما هو المؤتمر الصحفي؟', 'مؤتمر صحفي تصريح', sprintf('يُعقد قبل المباراة بـ %d دقيقة: تختار تصريحك الرسمي، وهو يرفع معنويات لاعبيك.', $c('press.open_minutes'))],
                ['What is the press conference?', 'press conference statement', sprintf('It is held %d minutes before the match: you choose your official statement, and it lifts your players\' morale.', $c('press.open_minutes'))]),
            $t('tickets', ['match'], 'match',
                ['ما هي تذاكر التشجيع؟', 'تذكرة تذاكر تشجيع احضر', 'تحضر مباريات منافسيك وتشجّع أحد الفريقين: كل تذكرة ترفع معنوياته في تلك المباراة، فتؤثر في سباق الترتيب.'],
                ['What are cheering tickets?', 'ticket tickets cheer attend', 'You attend your rivals\' matches and cheer for one side: every ticket lifts its morale in that match, so you shape the race for the table.']),
            $t('report', ['match'], 'match',
                ['ما هو تقرير المباراة؟', 'تقرير المباراة لماذا خسرت فزت اسباب ملخص سريع فاتتني', 'بعد كل مباراة يصلك تقريرها: أهم أسباب النتيجة، وشيء واحد تحسّنه، وتقييم كل لاعب، ورجل المباراة، وملاحظات المساعد. وإن فاتتك المباراة فالملخص السريع يعرض أهم لحظاتها (الأهداف والبطاقات والتبديلات) في ثوانٍ ثم الأرقام، ولك أن تتخطاه إلى النتيجة. ويمكنني أن أقرأ التقرير لك وأحلله.'],
                ['What is the match report?', 'report match why won lost reasons recap quick missed', 'After every match its report reaches you: the main reasons for the result, one thing to improve, each player\'s rating, the man of the match and your assistant\'s notes. If you missed the match, the quick recap plays its big moments (goals, cards, substitutions) in seconds and then the numbers, and you can skip to the result. I can read the report and analyse it for you.']),

            // The league.
            $t('cup', ['league'], 'league',
                ['كيف تعمل الكأس؟', 'كاس الكأس بطولة خروج المغلوب', 'الكأس خروج المغلوب من مباراة واحدة. الأقوى معفون من الدور التمهيدي، والقرعة عشوائية.'],
                ['How does the cup work?', 'cup knockout tournament', 'The cup is single-match knockout. The strongest skip the preliminary round, and the draw is random.']),
            $t('invite', ['league', 'leagues'], 'leagues',
                ['كيف أدعو أصحابي لدوريي؟', 'دعوة ادعو صحابي اصدقاء كود رابط', 'شارك كود الدوري أو رابطه: الرابط يفتح صفحة الانضمام بالكود جاهزاً، فيرسلون طلباً، وتوافق أنت، ثم يختارون فرقهم.'],
                ['How do I invite friends to my league?', 'invite friends code link', 'Share the league\'s code or link: the link opens the join page with the code filled in, they send a request, you approve it, and then they pick their teams.']),
            $t('leagues_create', ['home', 'leagues'], 'leagues',
                ['كيف أنشئ دورياً؟', 'انشاء انشئ دوري جديد خاص', sprintf('من «دورياتي» اضغط إنشاء دوري. بعد الإنشاء تختار فريقك وتحصل على كود تشاركه، والفرق الأخرى يديرها الحاسوب حتى ينضم أصحابك. الإعدادات المجانية بلا مقابل، والمخصص %d كوينز لكل نادٍ مرة واحدة.', $c('league.custom_coins_per_club'))],
                ['How do I create a league?', 'create new league private', sprintf('From «My leagues» tap create a league. After creating it you pick your team and get a code to share, and the other teams are run by the computer until your friends join. The free settings cost nothing; a customized league is %d coins per club, once.', $c('league.custom_coins_per_club'))]),
            $t('leagues_join', ['home', 'leagues'], 'leagues',
                ['كيف أنضم إلى دوري؟', 'انضم انضمام دوري صاحبي كود', sprintf('اطلب من صاحبك كود دوريه (%d أحرف)، واكتبه في صفحة الانضمام. تنتظر موافقة صاحب الدوري، ثم تختار فريقاً بلا مدرب قبل أن يسبقك أحد. وميزانيته عند الاستلام بين 500 ألف وميزانية البداية.', $c('league.code_length'))],
                ['How do I join a league?', 'join league friend code', sprintf('Ask your friend for their league\'s code (%d characters) and type it on the join page. You wait for the league owner\'s approval, then pick a team without a coach before anyone beats you to it. Its budget when you take it is between 500 thousand and the starting budget.', $c('league.code_length'))]),
            $t('vacation_league', ['league'], 'league',
                ['كيف آخذ إجازة من دوري؟', 'اجازة غياب دوري مسافر', sprintf('إجازة في دوري واحد (مرة في الموسم، حتى %d أيام) تحتاج سبباً يوافق عليه مسؤول الدوري. ولإجازة تشمل كل دورياتك بلا طلب: إجازة الحساب من «حسابي». والغائب بلا إجازة %d أيام قد يُطرد من الدوري.', $c('league.vacation_max_days'), $c('league.absence_days'))],
                ['How do I take a holiday from a league?', 'holiday vacation absence league away', sprintf('A holiday in one league (once a season, up to %d days) needs a reason the league\'s admin approves. For a holiday across all your leagues with no request: the account holiday in «My account». Someone away without a holiday for %d days may be removed from the league.', $c('league.vacation_max_days'), $c('league.absence_days'))]),
            $t('vacation_account', ['profile'], 'profile',
                ['ما هي إجازة الحساب؟', 'اجازة الحساب كله حذف غياب', sprintf('إجازة لحسابك كله تحميه من الحذف: لا يُحسب غيابك في أي دوري، والمدرب المساعد يقود فرقك. حتى %d أيام تبدأ فوراً (مرتين في الموسم)، والأطول يراجعها فريق التطوير.', $c('account.auto_vacation_days'))],
                ['What is the account holiday?', 'account holiday vacation delete absence', sprintf('A holiday for your whole account protects it from deletion: your absence counts in no league, and the assistant coach runs your teams. Up to %d days start at once (twice a season); longer ones are reviewed by the development team.', $c('account.auto_vacation_days'))]),
            $t('alliance', ['league'], 'league',
                ['ما هي بطولة التحالفات؟', 'تحالف تحالفات بطولة فرق', 'تحالفان من مدربي الدوري، والباقون يُوزعون عشوائياً. تُرسل للمطورين للاعتماد قبل أن تبدأ. والزميلان لا يلتقيان، ويختار قائدهما من يتأهل إن استحال غير ذلك. ينشئها منشئ الدوري.'],
                ['What is the alliance tournament?', 'alliance tournament teams', 'Two alliances of the league\'s coaches, with the rest spread at random. It goes to the developers for approval before it starts. Teammates never meet, and their leader picks who goes through if nothing else is possible. The league\'s creator sets it up.']),
            // [Sprint 27] The chat groups, the tournaments, the national teams and their draw.
            $t('groups', ['groups', 'home'], 'groups',
                ['ما هي الجروبات؟', 'جروب جروبات دردشة شات واتساب رسائل اصدقاء', 'الجروبات دردشة جماعية مثل واتساب داخل اللعبة. أنشئ جروباً وأضف أصدقاءك بأسماء المستخدمين، أو شارك رابطه فينضم من يفتحه. منشئ الجروب مشرف يضيف ويُخرج ويغيّر الاسم ويجعل غيره مشرفاً. اضغط أي رسالة لترد عليها أو تحذفها.'],
                ['What are the groups?', 'group groups chat whatsapp messages friends', 'Groups are group chats, like WhatsApp, inside the game. Make one and add your friends by their usernames, or share its link and whoever opens it joins. Its maker is an admin who adds, removes, renames and makes others admins. Tap any message to reply to it or delete it.']),
            $t('league_group', ['groups', 'league'], 'groups',
                ['ما هو جروب الدوري؟', 'جروب الدوري البطولة مدربين دردشة', 'كل دوري وكل بطولة لهما جروب، أعضاؤه منشئه ومدربوه، ويتغيرون معه: من ينضم يدخل ومن يغادر يخرج. افتحه من صفحة الدوري.'],
                ['What is the league group?', 'league group tournament coaches chat', 'Every league and tournament has a group of its maker and its coaches, changing with them: whoever joins comes in, whoever leaves goes out. Open it from the league page.']),
            $t('tournaments', ['tournaments', 'leagues'], 'tournaments',
                ['كيف أنشئ بطولة؟', 'بطولة بطولات كاس العالم امم افريقيا اوروبا اسيا اندية مخصصة مجموعات خروج المغلوب', 'من «البطولات» ← «بطولة جديدة»: اختر قالباً (كأس العالم، أو كأس العالم للأندية، أو أمم أفريقيا أو أوروبا أو آسيا، أو بطولة مخصصة) فتُملأ الفرق والشكل، وعدّل ما تشاء: من فريقين حتى 32 من المنتخبات والأندية معاً. والنظام: دوري، أو مجموعات ثم إقصاء (1 أو 2 أو 4 أو 8 مجموعات، ويتأهل الأول أو الأولان)، أو خروج المغلوب. ينضم المدربون بكودها ويطلبون فريقاً كالدوري، ولا سوق فيها: كل فريق يلعب بقائمته.'],
                ['How do I make a tournament?', 'tournament world cup nations africa europe asia clubs custom groups knockout', 'From Tournaments, New tournament: pick a template (World Cup, Club World Cup, Africa, Europe or Asia, or custom) and the teams and shape fill in, then change what you like: two to 32 teams, national teams and clubs together. The format: a league, groups then a knockout (1, 2, 4 or 8 groups, the first one or two through), or a knockout. Coaches join with its code and ask for a team as in a league, and there is no market: every team plays with its squad.']),
            $t('national_teams', ['tournaments'], 'tournaments',
                ['من أين جاءت المنتخبات؟', 'منتخب منتخبات دولة جنسية لاعبين قائمة', 'كل منتخب من لاعبي جنسيته في البيانات: أفضل 23 (منهم 3 حراس). ويلعب المنتخب إن كان له 14 لاعباً وحارس على الأقل، والباقي يكمّله الأدمن من محرر البيانات. ولو اخترت نادياً ومنتخباً معاً بقي لاعب النادي مع ناديه وأخذ المنتخب من بعده.'],
                ['Where do the national teams come from?', 'national team nation country nationality players squad', 'Each national team is made from the players of its nationality in the data: its best 23 (three of them keepers). A country plays when it has at least 14 players and a keeper; the admin completes the rest in the data editor. If you pick a club and a national team together, the club keeps its players and the nation takes the next best.']),
            $t('tournament_draw', ['tournaments'], 'tournaments',
                ['كيف تعمل قرعة البطولة؟', 'قرعة البطولة مباشرة وعاء اعادة صوت', 'يحدد المنظم موعد قرعة مباشرة يشاهدها كل اللاعبين في نفس اللحظة: كرة تخرج من الوعاء، ثم يُكشف الفريق ويُنطق اسمه ويذهب إلى مجموعته. وفي المجموعات تُقسم الفرق أوعية بقوتها، وفي كل مجموعة فريق من كل وعاء. وبلا موعد تُسحب عند البداية، ومن فاتته يعيد مشاهدتها كما كانت بالضبط، ويتحقق منها ببصمتها المعلنة قبلها.'],
                ['How does the tournament draw work?', 'tournament draw live pot replay sound', 'The organizer sets a live draw every player watches at the same moment: a ball leaves the bowl, the team is revealed, its name is said aloud, and it goes to its group. In groups the teams are split into pots by strength, one from each pot in every group. With no time set it is drawn at the start; whoever missed it replays it exactly as it was, and checks it against its fingerprint announced beforehand.']),
            $t('draw', ['league'], 'league',
                ['ما هي القرعة المباشرة؟', 'قرعة القرعه البصمة ترتيب', 'منشئ الدوري يحدد موعد قرعة مباشرة قبل البداية، وتُعلن بصمتها مسبقاً فلا يستطيع أحد تغيير النتيجة. وبدونها تُرتّب الأندية بقوتها عند البداية.'],
                ['What is the live draw?', 'draw fingerprint order', 'The league\'s creator schedules a live draw before the start, and its fingerprint is announced beforehand so nobody can change the result. Without one, the clubs are ordered by their strength at the start.']),
            $t('stats', ['stats', 'fixtures'], 'stats',
                ['ماذا في جدول الدوري والمباريات؟', 'جدول الترتيب احصائيات الهدافين المباريات الجولات', 'جدول الدوري فيه الترتيب وكل ما يراه أعضاء الدوري عن الموسم: الهدافون وصناع الأهداف والبطاقات. وجدول المباريات فيه الموسم كله جولة بجولة. اضغط اسم أي نادٍ لترى تشكيلته ولاعبيه.'],
                ['What is in the table and the fixtures?', 'table standings stats scorers fixtures rounds', 'The league table has the standings and everything the league\'s members see about the season: scorers, assists and cards. The fixtures have the whole season round by round. Tap any club\'s name to see its lineup and players.']),
            $t('newspaper', ['newspaper'], 'newspaper',
                ['ما هي جريدة الدوري؟', 'جريدة اخبار مقال الدوري', 'جريدة الدوري تصدر بعد كل جولة بأخبارها. وتكتب فيها خبراً، أو بياناً، أو صفقة، أو رسالة لمنافسيك، ويُنشر بعد موافقة مشرف الدوري. مقال واحد لكل مدرب في كل جولة.'],
                ['What is the league newspaper?', 'newspaper news article', 'The league\'s newspaper comes out after every round with its news. You write in it a story, a statement, a deal or a message to your rivals, published once the league\'s moderator approves it. One article per coach per round.']),
            $t('predictions', ['predictions'], 'predictions',
                ['كيف تعمل التوقعات؟', 'توقع توقعات نتيجة', 'توقّع نتائج مباريات الجولة قبل بدايتها: كل توقع صحيح يمنح ناديك مالاً.'],
                ['How do predictions work?', 'predict predictions result', 'Predict the round\'s results before it starts: every right prediction earns your club money.']),

            // The account.
            $t('verification', ['profile', 'wallet'], 'profile',
                ['كيف أوثّق حسابي؟', 'توثيق وثق الحساب كود مكافاة ترحيب', sprintf('من «حسابي» نرسل لك كوداً من 6 أرقام على بريدك، صالحاً %d دقيقة ولمرة واحدة. وبتوثيق الحساب تصلك مكافأة %d كوينز.', $c('account.verify_code_minutes'), $c('account.welcome_coins'))],
                ['How do I verify my account?', 'verify account code welcome reward', sprintf('From «My account» we send a 6-digit code to your email, valid for %d minutes and once only. Verifying your account brings a reward of %d coins.', $c('account.verify_code_minutes'), $c('account.welcome_coins'))]),
            $t('referral', ['profile', 'wallet'], 'profile',
                ['كيف أكسب من دعوة أصدقائي؟', 'دعوة رابط صديق اصدقاء احالة', sprintf('انسخ رابط الدعوة من «حسابي». كل مدرب يسجّل من رابطك ويوثّق حسابه يمنحك %d كوينز، حتى %d دعوات.', $c('account.referral_coins'), $c('account.referral_max'))],
                ['How do I earn from inviting friends?', 'invite referral link friend', sprintf('Copy the invite link from «My account». Every coach who signs up from your link and verifies their account gives you %d coins, up to %d invites.', $c('account.referral_coins'), $c('account.referral_max'))]),
            $t('inbox', ['inbox'], 'inbox',
                ['ماذا يصلني في الرسائل؟', 'رسائل الرسائل صندوق اشعارات', 'في الرسائل يصلك حكم مباراتك، وتقاريرها، وطلبات الانضمام، وإعلانات فريق التطوير، وكل ما يخص دورياتك.'],
                ['What reaches my inbox?', 'inbox messages notifications', 'Your inbox brings your match\'s referee, its reports, join requests, the development team\'s announcements, and everything about your leagues.']),
            $t('support', ['support'], 'support',
                ['كيف أراسل فريق التطوير؟', 'دعم مشكلة شكوى اقتراح المطورين تواصل', 'من صفحة الدعم: رسائلك تصل لحسابات المطورين الرسمية، وردودهم تصلك هناك وفي صندوق رسائلك.'],
                ['How do I contact the development team?', 'support problem complaint suggestion developers contact', 'From the support page: your messages reach the developers\' official accounts, and their replies reach you there and in your inbox.']),

            // [X61] What the fixes and the new features added.
            $t('basic_coach', ['training', 'specialists'], 'training',
                ['هل أدرّب بلا مدرب خط؟', 'مدرب اساسي مجاني بلا مدرب تدريب مقفل', sprintf('نعم: كل خط بلا مدرب من الجهاز الفني يدرّبه المدرب الأساسي المجاني، أسرع بـ %d%%. والمدرب المتعاقد معه أسرع حسب نجومه، وتصل إليه من زر «تعاقد مع مدرب الآن» في خانة التدريب.', intdiv((int) $c('specialists.basic_coach_bp'), 100))],
                ['Can I train without a line coach?', 'basic free coach no coach training locked', sprintf('Yes: a line without a coach from the staff trains with the free basic coach, %d%% faster. A signed coach is faster by his stars; reach him from «Sign a coach now» in the training slot.', intdiv((int) $c('specialists.basic_coach_bp'), 100))]),
            $t('ticket_price', ['finance', 'stadium'], 'finance',
                ['كيف أحدد سعر التذاكر؟', 'تذاكر سعر التذكرة دخل الحضور جمهور', 'من المالية أو الملعب: أربعة مستويات. الشعبي يملأ المدرجات بسعر أقل، والمرتفع والمميز بسعر أعلى وحضور أقل. ويُحسب الدخل بعد كل مباراة على أرضك بالمستوى الذي اخترته، وأفضلها يزيد قليلاً لنادٍ يملأ ملعبه.'],
                ['How do I set the ticket price?', 'tickets ticket price gate attendance crowd', 'From finance or the stadium: four levels. Popular fills the stands for less, high and premium cost more with a smaller crowd. The gate is posted after each home match at the level you chose; the best one earns a little more for a club that fills its stadium.']),
            $t('contracts', ['finance', 'team'], 'finance',
                ['ما العقود وسقف الرواتب؟', 'عقد عقود راتب رواتب سقف انهاء فسخ تعويض', sprintf('كل لاعب راتبه جزء من رواتب ناديك، والعقود تنتهي بنهاية الموسم. سقف الرواتب يمنع ضم لاعب يتجاوز قدرة ناديك. ويمكنك إنهاء عقد لاعب من المالية، فيغادر إلى السوق وتدفع %d%% من رواتبه الباقية في الموسم.', intdiv((int) $c('contracts.release_bp'), 100))],
                ['What are contracts and the wage cap?', 'contract contracts wage wages cap release end compensation', sprintf('Each player\'s wage is his share of your club\'s wages, and contracts end with the season. The wage cap stops a signing your club cannot carry. You can end a contract from finance: the player leaves for the market and you pay %d%% of his wages left this season.', intdiv((int) $c('contracts.release_bp'), 100))]),
            $t('loans', ['market'], 'market',
                ['كيف أستعير لاعباً؟', 'اعارة استعارة اعير لاعب معار', sprintf('اضغط اسم نادي مدرب في دوريك، ثم «إعارة» بجانب اللاعب: من جولة إلى %d جولات، ومقابل حتى %d%% من قيمته. إن قبل مدربه انتقل إليك، ويعود وحده بعد آخر جولة. والطلبات في تبويب «الإعارات» في السوق.', (int) $c('loans.max_rounds'), intdiv((int) $c('loans.max_fee_bp'), 100))],
                ['How do I take a player on loan?', 'loan borrow lend player on loan', sprintf('Tap a coach\'s club name in your league, then «Loan» beside the player: 1 to %d rounds, for up to %d%% of his value. If his coach accepts he joins you, and goes back by himself after the last round. Requests are in the market\'s «Loans» tab.', (int) $c('loans.max_rounds'), intdiv((int) $c('loans.max_fee_bp'), 100))]),
            $t('academy', ['market', 'training'], 'market',
                ['ما أكاديمية الشباب؟', 'اكاديمية شباب ناشئين موهبة مواهب صغار', sprintf('كل %d أيام تعرض أكاديميتك %d مواهب لا تتجاوز %d عاماً، إمكانيتها مخفية في مدى حتى توقّع معها. تكلف أقل من قيمتها، ولك %d توقيعات في الموسم. وتجدها في تبويب «الأكاديمية» في السوق.', (int) $c('academy.days'), (int) $c('academy.offers'), (int) $c('academy.max_age'), (int) $c('academy.per_season'))],
                ['What is the youth academy?', 'academy youth prospects young talent', sprintf('Every %d days your academy offers %d prospects aged %d or under, their potential a hidden range until you sign one. They cost less than their value, and you have %d signings a season. Find it in the market\'s «Academy» tab.', (int) $c('academy.days'), (int) $c('academy.offers'), (int) $c('academy.max_age'), (int) $c('academy.per_season'))]),
            $t('awards', ['stats', 'league'], 'stats',
                ['ما الأوسمة؟', 'اوسمة جوائز افضل لاعب هداف نجم الجولة شاب', sprintf('في الإحصائيات تبويب «الأوسمة»: أفضل لاعب (أعلى متوسط تقييم بعد %d مباريات على الأقل)، وأفضل شاب (%d عاماً فأقل)، ونجم آخر جولة، والهداف، وصانع الألعاب، وأطول سلسلة انتصارات.', (int) $c('awards.min_matches'), (int) $c('awards.young_age'))],
                ['What are the awards?', 'awards best player top scorer player of the round young', sprintf('The stats\' «Awards» tab: the best player (the highest average rating after %d matches at least), the best young one (%d or under), the last round\'s star, the top scorer, the top assister and the longest winning run.', (int) $c('awards.min_matches'), (int) $c('awards.young_age'))]),
            $t('press_stakes', ['match'], 'match',
                ['ماذا يفعل تصريحي في المؤتمر الصحفي؟', 'مؤتمر صحفي تصريح وعد معنويات عواقب', 'يرفع معنويات لاعبيك في المباراة، ثم تحكم النتيجة عليه: الوعد بالفوز الكاسح يكافئك إن فزت ويكلفك إن خسرت، والهادئ آمن، والحماسي بينهما. وتظهر أرقام كل تصريح تحته.'],
                ['What does my press statement do?', 'press conference statement promise morale stakes', 'It lifts your players\' morale in the match, then the result judges it: promising a crushing win pays if you win and costs if you lose, the calm one is safe, the rallying one in between. Each statement shows its numbers under it.']),
        ];
    }
}
