<?php

namespace App\Assistant;

use App\Engine\Ability;
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
        'profile', 'leagues', 'support', 'ideas', 'groups', 'tournaments', 'store'];

    /** A route of the web that is a page of another name here. */
    private const ALIASES = ['league-home' => 'league', 'league-newspaper' => 'newspaper', 'league-predictions' => 'predictions',
        'league-alliance' => 'league', 'league-draw' => 'league', 'create-league' => 'leagues', 'join' => 'leagues',
        'pick-team' => 'leagues', 'coach' => 'home', 'announcements' => 'home', 'league-report' => 'match',
        // [Sprint 29] The chat groups and the tournaments.
        'group' => 'groups', 'group-join' => 'groups', 'create-tournament' => 'tournaments', 'tournament' => 'tournaments', 'tournament-draw' => 'tournaments'];

    /** The pages an answer may open, by the web's section names. */
    public const GO = ['club', 'team', 'lineup', 'tactics', 'training', 'specialists', 'market', 'scout', 'stadium', 'finance',
        'quests', 'match', 'league', 'fixtures', 'stats', 'friendlies', 'newspaper', 'predictions', 'inbox', 'wallet', 'profile',
        'leagues', 'support', 'ideas', 'groups', 'tournaments', 'store'];

    /**
     * Each page's quick questions: a topic's id is answered from the guide at once; text after "?" goes to the
     * assistant to read the coach's own club.
     */
    private const QUICK = [
        'home' => ['rating', 'slots', 'leagues_create', 'leagues_join', 'coins', '?analysis_overview'],
        'club' => ['club_board', 'objectives', 'contract', 'friendlies', 'quests', '?analysis_overview'],
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
        'store' => ['store', 'coins'],
        'match' => ['next_match', 'match_move', 'opponent_sees', 'spy', 'live_changes', 'integrity', '?analysis_last'],
        'league' => ['cup', 'rest_days', 'invite', 'vacation_league', 'alliance', 'draw'],
        'fixtures' => ['stats', 'next_match'],
        'stats' => ['stats', 'awards', '?analysis_overview'],
        'friendlies' => ['friendlies'],
        'newspaper' => ['newspaper'],
        'predictions' => ['predictions'],
        'inbox' => ['inbox'],
        'wallet' => ['coins', 'referral', 'verification'],
        'profile' => ['verification', 'referral', 'vacation_account'],
        'leagues' => ['leagues_create', 'leagues_join', 'invite'],
        'support' => ['support', 'ideas'],
        'ideas' => ['ideas', 'polls', 'honour_roll'],
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
                ['ما هو هدف النادي؟', 'هدف النادي الادارة المطلوب مني المجلس اقالة', 'إدارة النادي تحدد لك هدفاً أول الموسم من قوة ناديك بين أندية دوريك: أقوى ناديين يُطلب منهما اللقب، وكل نادٍ بعدهما مركزه حسب ترتيب قوته أو أفضل، وأضعف ثلاثة النجاة من المراكز الأخيرة. تحقيقه يمنحك كوينز في آخر الموسم.'],
                ['What is the club objective?', 'objective board target goal season', 'The board sets you an objective at the start of the season from your club\'s strength among its league: the two strongest are asked for the title, every club after them for its place by strength or better, and the three weakest to stay out of the bottom places. Reaching it earns you coins at the end of the season.']),
            $t('friendlies', ['club', 'friendlies'], 'friendlies',
                ['ما هي المباريات الودية؟', 'ودية وديات ودي تجريبية', sprintf('الودية مباراة الآن تُحاكى كاملة، وتراها محاكاة سريعة في الصفحة نفسها (دقائقها وفرصها وأهدافها في نحو 15 ثانية، أو «تخطَّ إلى النتيجة»)، بلا أثر على جدول الدوري وترتيبه ولا على المال: تجرّب بها تكتيكك وتجهّز لاعبيك. كل من يلعب يكسب %d لياقة، و%s%% من تدريبه، وتُحسب مباراة معاً في الانسجام. ثمنها %d كوينز تُخصم حين تؤكد بدء الودية، بلا حد، وودية واحدة مع كل نادٍ في اليوم. وأول ودية في حسابك مجانية، ولك هدية بداية %d كوينز تستلمها من الرئيسية بزر «استلم مكافأتك».', $c('friendlies.fitness'), rtrim(rtrim(number_format($c('friendlies.training_progress') / 100, 2), '0'), '.'), $c('friendlies.coins'), $c('account.starter_coins'))],
                ['What are friendlies?', 'friendly friendlies test match', sprintf('A friendly is a match now, played whole, and you watch it as a quick simulation on the same page (its minutes, chances and goals in about 15 seconds, or «Skip to the result»), with no effect on the league table or the money: you try your tactics and get your players ready. Everyone who plays gains %d fitness and %s%% of their training, and it counts as a match together for the chemistry. It costs %d coins, taken when you confirm it, with no limit, and one friendly a day against each club. Your account\'s first friendly is free, and a starter gift of %d coins waits on the home screen behind «Claim your reward».', $c('friendlies.fitness'), rtrim(rtrim(number_format($c('friendlies.training_progress') / 100, 2), '0'), '.'), $c('friendlies.coins'), $c('account.starter_coins'))]),
            // [Sprint 27 B1, B2] Days off and moving a match.
            $t('rest_days', ['league', 'leagues'], 'league',
                ['ما هي أيام الإجازة في الدوري؟', 'اجازة اجازه ايام الاجازة راحة الجمعة يوم بلا مباريات عطلة', sprintf('منشئ الدوري يختار قبل بدايته حتى %d أيام في الأسبوع بلا مباريات (الجمعة مثلاً)، مجاناً. فيتخطاها جدول الموسم، وتُلعب الجولات في الأيام الأخرى، فيطول الموسم قليلاً. ويغيّرها من صفحة الدوري حتى يبدأ.', $c('league.rest_days_max'))],
                ['What are the league\'s days off?', 'days off rest day friday holiday no matches', sprintf('Before the start, the league\'s creator chooses up to %d days a week with no matches (Friday, say), for free. The season\'s calendar steps over them and the rounds are played on the other days, so the season gets a little longer. They can be changed on the league page until it starts.', $c('league.rest_days_max'))]),
            $t('match_move', ['match'], 'match',
                ['كيف أقدّم مباراتي أو أؤجلها؟', 'تقديم تأجيل اجل قدم موعد المباراة تغيير الموعد ساعة نقل المباراة', sprintf('من «المباراة القادمة» ← «تقديم المباراة أو تأجيلها»: اختر ساعة أبكر أو أبعد في اليوم نفسه (حتى %d ساعات)، فيصل الطلب للمدرب الآخر ليوافق أو يرفض (ونادي الحاسوب يوافق فوراً). والموعدان يجب أن يكونا بعد ساعة على الأقل من الآن، وبعيدين ساعة عن مباريات الناديين الأخرى، ويُغيّر موعد المباراة الواحدة %d مرات على الأكثر. والطلب الذي لا يُرد عليه ينتهي قبل الموعد بساعة.', $c('match_moves.max_hours'), $c('match_moves.max_per_fixture'))],
                ['How do I bring my match forward or put it back?', 'move match time earlier later postpone reschedule hour', sprintf('From Next match → «Bring the match forward or put it back»: pick an hour earlier or later the same day (up to %d hours), and the request goes to the other coach to accept or decline (a computer club agrees at once). Both times must be at least an hour from now and an hour from either club\'s other matches, and a match moves %d times at most. A request with no answer lapses an hour before the match.', $c('match_moves.max_hours'), $c('match_moves.max_per_fixture'))]),
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
                ['كيف أعدّل التشكيلة؟', 'تشكيلة تشكيله تعديل اسحب تبديل الاحتياط ابدل لاعب', sprintf('اضغط أي مكان في الملعب فتظهر قائمة «من يلعب هنا؟» بقوة كل لاعب في هذا المكان، الأنسب أولاً، ويمكن تصفيتها بالخط، فاختر واحداً (ومن في الملعب يتبادل معه). أو اضغط لاعباً في الاحتياط أو باقي الفريق فتظهر «أين يلعب؟» بكل الأماكن وقوته في كل منها. أو اسحب اللاعب إلى لاعب آخر ليتبادلا، أو إلى أي مكان داخل منطقة خطه ليقف فيه. كل تغيير يُحفظ وحده بعد لحظة، و«تراجع» يعيد آخر تغيير. ويمكن أن تضع أي لاعب ميدان في أي خط، لكنه خارج مركزه يلعب بـ %d%% من مستواه في الخط المجاور (مدافع في الوسط أو لاعب وسط في الهجوم)، وبـ %d%% بعد خطين (مدافع في الهجوم)، وتظهر النسبة على بطاقته. والجناح في مكانه على طرف الوسط أو الهجوم، وكذلك من له مركز ثانٍ في ذلك الخط. وخانة الحارس لحارس مرمى فقط. وبعد الحفظ تُحسب الكيمياء وروابطها من جديد.', intdiv(Ability::position(['line' => 'def', 'slot_line' => 'mid']), 100), intdiv(Ability::position(['line' => 'def', 'slot_line' => 'att']), 100))],
                ['How do I edit the lineup?', 'lineup edit drag swap bench substitute', sprintf('Tap any place on the pitch and «Who plays here?» lists each player with his rating in that place, the best first, filtered by line if you like: pick one (a player on the pitch swaps with him). Or tap a player on the bench or in the squad and «Where does he play?» shows every place with his rating there. Or drag a player onto another to swap them, or anywhere inside their line\'s area to place them. Every change saves itself a moment later, and «Undo» takes the last one back. Any outfield player can stand in any line, but out of position they play at %d%% of their level in the next line (a defender in midfield, a midfielder up front) and at %d%% two lines away (a defender up front), shown on their card. A winger is in place on the flank of midfield or attack, and so is a player whose second position is in that line. The goal is for a goalkeeper only. After saving, the chemistry and its links are worked out again.', intdiv(Ability::position(['line' => 'def', 'slot_line' => 'mid']), 100), intdiv(Ability::position(['line' => 'def', 'slot_line' => 'att']), 100))]),
            $t('takers', ['lineup'], 'lineup',
                ['من ينفذ الكرات الثابتة؟', 'منفذ ركلات جزاء ضربة حرة ركنية كورنر كابتن ثابتة', 'المتخصصون أربعة: القائد، وركلات الجزاء، والضربات الحرة، والركنيات. اضغط بطاقة أحدهم فتظهر قائمة الفريق كله مرتبة بمهارة هذا الدور، فاختر من تريد. وإن لم يكن من الأساسيين في مباراة ينفذها الأنسب منهم حتى يعود. و«تلقائي» يترك الاختيار للعبة، ولو خرج المنفذ من الملعب يختار المحرك بديله. والقائد الأنسب أكبر الأساسيين سناً (حتى 32) وأعلاهم تقييماً، وقائد أقل منهم بكثير يربك بناء اللعب، وأكثر والفريق متأخر. وركلة الجزاء لمهاجم يسدد جيداً، ومدافع أو لاعب وسط ضعيف التسديد يضيع كثيراً منها. والضربة الحرة بالتسديد والتمرير، والركنية بالعرضية والتمرير.'],
                ['Who takes the set pieces?', 'takers penalty free kick corner set piece captain', 'There are four specialists: the captain, penalties, free kicks and corners. Tap a card and your whole squad shows, ranked by that role\'s skill: pick whoever you want. If they are not in the eleven for a match, the best of the starters takes it until they are back. «Auto» leaves the choice to the game, and if the taker leaves the pitch the engine picks a replacement. The best captain is the oldest (up to 32) and highest rated of the eleven; one well below them unsettles the build-up, more so when behind. Penalties suit a forward who finishes well, and a defender or midfielder who shoots poorly misses many. Free kicks take shooting and passing, corners crossing and passing.']),

            // Tactics.
            $t('plan', ['tactics'], 'tactics', ['ما هي خطة اللعب؟', 'خطة اللعب مرتد مرتدات كرات طويلة تمريرات اجنحة تسديد بعيد', $help['plan']], ['What is the game plan?', 'plan counter long balls passes wings long shots', $help['plan']]),
            $t('pressing', ['tactics'], 'tactics', ['ماذا يفعل الضغط؟', 'ضغط عالي الضغط العالي منخفض بريس', $help['pressing']], ['What does pressing do?', 'pressing press high low', $help['pressing']]),
            // [Sprint 39 E4, E5, E7] The plan with its formation, the settings that work together, and the referee.
            $t('synergy', ['tactics', 'lineup'], 'tactics',
                ['أي خطة تناسب تشكيلتي؟', 'تناغم توافق خطة تشكيلة 433 442 451 532 352 اجنحة تمرير تسديد مرتدات', 'كل خطة لها تشكيلة تخدمها: ثلاثة في الهجوم (4-3-3) للعب على الأجناب، وأربعة في الوسط مع مهاجمَين (4-4-2) للتمرير، وخمسة في الوسط (4-5-1 و4-2-3-1) للتسديد من بعيد، وخمسة في الدفاع (5-3-2) للمرتدات، وأربعة في الهجوم للكرات الطويلة. والدفاع الثلاثي يناسب الأجناب والتمرير تقريباً. والخطة التي تناسب تشكيلتك تتقدم وتصنع الفرص أسهل، والتي تعاكسها أصعب: التسديد البعيد مع ثلاثة مهاجمين، والأجناب بمهاجم واحد، والكرات الطويلة فوق وسط رباعي، والتمرير بخمسة مدافعين.'],
                ['Which plan suits my formation?', 'synergy formation plan 433 442 451 532 wings passing shots counter', 'Each plan has a formation that serves it: three up front (4-3-3) for the wings, four in midfield with two strikers (4-4-2) for passing, five in midfield (4-5-1, 4-2-3-1) for long shots, five at the back (5-3-2) for counters, and four up front for long balls. A back three suits the wings and passing nearly as well. A plan that suits your formation gets through and makes chances more easily; one that clashes with it, less: long shots with three strikers, the wings with one, long balls over a midfield four, passing with a back five.']),
            $t('golden_triangle', ['tactics'], 'tactics',
                ['هل تعمل إعدادات التكتيك معاً؟', 'المثلث الذهبي تناقض الضغط الاسلوب الايقاع خطوط متباعدة', 'الضغط والأسلوب والإيقاع تعمل معاً: الهجوم المنظم ضغط 65-75 وأسلوب 65-75 وإيقاع 60-70، وامتصاص اللعب والمرتدات ضغط 30-45 وأسلوب 30-40 وإيقاع 65-75. وإذا تباعد الضغط عن الأسلوب كثيراً تتباعد خطوطك ويتقدم خصمك أسهل، وكذلك خمسة مدافعين بضغط وهجوم كاسحين، وثلاثة مدافعين بضغط منخفض. والمرتدات تحتاج مساحة: كلما رفعت الضغط معها قلّت فائدتها. ومصيدة التسلل تنجح مع ثلاثة مدافعين وضغط عالٍ، وتصير خطراً مع أربعة أو خمسة متراجعين. ورقابة المنطقة أفضل حين يزيد مدافعوك على مهاجمي الخصم، ورجل لرجل حين يساوونهم وهم أسرع وأقوى.'],
                ['Do my tactic settings work together?', 'golden triangle contradiction pressing style tempo stretched lines', 'Pressing, style and tempo work together: organised attack is pressing 65-75, style 65-75 and tempo 60-70; soaking up pressure and countering is pressing 30-45, style 30-40 and tempo 65-75. When pressing and style are far apart your lines stretch and your opponent gets through more easily; so do five defenders with an all-out press and attack, and three defenders sitting deep. Counters need space: the higher you press with them, the less they give. The offside trap works with three defenders and a high press, and is a danger with four or five sitting deep. Zonal marking is better when your defenders outnumber the forwards, man to man when they match them and are quicker and stronger.']),
            $t('referee_levels', ['tactics', 'match'], 'tactics',
                ['ما درجات الحكام؟', 'حكم الحكم صرامة متساهل صارم بطاقات طرد خشونة', 'الحكام خمس درجات: متساهل جداً، ومتساهل، ومتوسط، وصارم، وصارم جداً، ويُعلن حكم مباراتك قبلها بنصف ساعة. والأخطاء والبطاقات = صرامة الحكم × قوة قطعك للكرة: مع حكم متساهل تكسب بالقطع القوي صراعات أكثر بلا خوف كبير، ومع حكم صارم جداً والخشونة تكثر البطاقات والطرد وركلات الجزاء ضدك.'],
                ['What are the referee levels?', 'referee strictness lenient strict cards red tackling', 'Referees come in five levels: very lenient, lenient, medium, strict and very strict, and yours is named half an hour before the match. Fouls and cards = the referee\'s strictness × how hard you tackle: with a lenient referee a hard tackle wins more duels without much risk; with a very strict one and rough tackling, more cards, red cards and penalties against you.']),
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
                ['كم يأخذ بناء الملعب؟', 'وقت مدة بناء الملعب ساعة جزء', sprintf('تبني جزءاً واحداً في كل مرة، وتبدأ كل جزء بنفسك. الملعب كاملاً %d جزءاً، ومدة الجزء من طول دوريك: من يبني بلا توقف من بداية الموسم يكمله قبل نهاية الدوري بـ%d جولات (وصفحة الملعب تكتب مدة الجزء). فاختر أولوياتك: الدخل (المقاعد)، أو ميزة الأرض (الأرضية)، أو سرعة التدريب (المنشأة).', $c('stadium.stages') * $c('stadium.parts_per_stage') * count($c('stadium.sections')), $c('stadium.finish_before_rounds'))],
                ['How long does the stadium take?', 'time build stadium hours part', sprintf('You build one part at a time and start each part yourself. The full stadium is %d parts, and a part\'s time comes from your league\'s length: building without a break from the season\'s start finishes it %d rounds before the league ends (the stadium page shows a part\'s time). So choose your priorities: income (seats), home advantage (pitch) or training speed (facility).', $c('stadium.stages') * $c('stadium.parts_per_stage') * count($c('stadium.sections')), $c('stadium.finish_before_rounds'))]),
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
                ['ما هي الكوينز؟', 'كوينز كوين عملات ذهب نقاط شراء', sprintf('الكوينز عملتك أنت لا عملة النادي، وتُكسب داخل اللعبة فقط: الدخول اليومي (%d)، والفوز (%d)، والتعادل (%d)، وتحقيق الأهداف، والألقاب، والمهام. والخسارة لا تعطي شيئاً، ومن يخسر أمام مدرب أقل منه تصنيفاً يُخصم منه %d. تنهي بها الانتظار وتشتري بها مزايا مثل الجاسوس، ولا تتحول أبداً إلى أموال نادٍ. والشراء الحقيقي بعد النسخة الأولى، فالآن الكل متساوٍ.', $c('premium.earn.daily'), $c('premium.earn.win'), $c('premium.earn.draw'), $c('premium.upset_loss'))],
                ['What are coins?', 'coins coin gold currency buy', sprintf('Coins are your own currency, not the club\'s, earned only in the game: the daily login (%d), a win (%d), a draw (%d), reaching objectives, titles and quests. A loss gives nothing, and losing to a coach of a lower rating tier costs %d. They end waits and buy features like the spy, and never turn into club money. Real purchases come after the first version, so for now everyone is equal.', $c('premium.earn.daily'), $c('premium.earn.win'), $c('premium.earn.draw'), $c('premium.upset_loss'))]),

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
            // [X69] Any finished match of the league, again in full or as a quick recap.
            $t('replays', ['fixtures', 'match'], 'fixtures',
                ['كيف أشاهد مباراة انتهت؟', 'اعادة إعادة شاهد محاكاة مباراة انتهت الجولة الاخيرة ملخص مباريات الدوري', 'من «جدول المباريات»: في أعلاه آخر مباراة لك وكل مباريات الجولة الأخيرة، ولكل واحدة «ملخص» يعرض أهم لحظاتها في ثوانٍ و«شاهد المحاكاة» يعيدها كاملة على الملعب كما لُعبت، بالسرعة التي تختارها ولك أن تتخطى إلى النهاية. واضغط نتيجة أي مباراة انتهت في الدوري لترى ملخصها ثم محاكاتها. كل أعضاء الدوري يشاهدون كل مبارياته، ولا يظهر تكتيك أي فريق إلا لمدربه. والإعادة متاحة حتى تبدأ الجولة التالية، ثم تبقى النتيجة والملخص وحدهما. ومن يدخل مباراة جارية يشاهدها مباشرة من دقيقتها.'],
                ['How do I watch a finished match?', 'replay watch again finished match simulation last round recap league matches', 'From the fixtures: at the top are your last match and every match of the last round, each with «Recap», its big moments in seconds, and «Watch», the whole match again on the pitch as it was played, at the speed you pick, and you can skip to the end. Tap the score of any finished league match to see its recap and then its simulation. Every member of the league watches all its matches, and a side\'s tactics show only to its own coach. A match can be watched again until the next round starts; then its result and recap stay. Joining a match under way, you watch it live from that minute.']),

            // The league.
            $t('cup', ['league'], 'league',
                ['كيف تعمل الكأس؟', 'كاس الكأس بطولة خروج المغلوب', 'الكأس خروج المغلوب من مباراة واحدة، وشجرتها كاملة من أول الموسم. الأقوى معفون من الدور التمهيدي، والقرعة توزع الأقوياء على كل الأفرع: أقوى ناديين لا يلتقيان إلا في النهائي، وأقوى أربعة إلا في نصف النهائي، ويُسحب الباقون ضدهم.'],
                ['How does the cup work?', 'cup knockout tournament', 'The cup is single-match knockout, its whole bracket drawn at the start of the season. The strongest skip the preliminary round, and the draw spreads the strongest over every branch: the two strongest meet only in the final, the four strongest only in the semi-finals, and the rest are drawn against them.']),
            $t('invite', ['league', 'leagues'], 'leagues',
                ['كيف أدعو أصحابي لدوريي؟', 'دعوة ادعو صحابي اصدقاء كود رابط', 'شارك كود الدوري أو رابطه: الرابط يفتح صفحة الانضمام بالكود جاهزاً، فيرسلون طلباً، وتوافق أنت، ثم يختارون فرقهم.'],
                ['How do I invite friends to my league?', 'invite friends code link', 'Share the league\'s code or link: the link opens the join page with the code filled in, they send a request, you approve it, and then they pick their teams.']),
            $t('leagues_create', ['home', 'leagues'], 'leagues',
                ['كيف أنشئ دورياً؟', 'انشاء انشئ دوري جديد خاص', sprintf('من «دورياتي» اضغط إنشاء دوري. بعد الإنشاء تختار فريقك وتحصل على كود تشاركه، والفرق الأخرى يديرها الحاسوب حتى ينضم أصحابك. الإعدادات المجانية بلا مقابل، والمخصص %d كوينز لكل نادٍ مرة واحدة: من فريقين فأكثر، وبفترة إعداد يومين أو 4 أو 6 أو بلا إعداد فتبدأ المباريات من أول يوم. وجروب الدوري يُنشأ معه، يدخله كل من يأخذ فريقاً، ويبقى حتى ينتهي الدوري ثم للقراءة فقط.', $c('league.custom_coins_per_club'))],
                ['How do I create a league?', 'create new league private', sprintf('From «My leagues» tap create a league. After creating it you pick your team and get a code to share, and the other teams are run by the computer until your friends join. The free settings cost nothing; a customized league is %d coins per club, once: from two teams, with 2, 4 or 6 days to get ready or none, so the matches start on the first day. The league\'s group is made with it, everyone who takes a team joins it, and it stays open until the league ends, then read-only.', $c('league.custom_coins_per_club'))]),
            $t('leagues_join', ['home', 'leagues'], 'leagues',
                ['كيف أنضم إلى دوري؟', 'انضم انضمام دوري صاحبي كود', sprintf('اطلب من صاحبك كود دوريه (%d أحرف)، واكتبه في صفحة الانضمام. تنتظر موافقة صاحب الدوري، ثم تختار فريقاً بلا مدرب قبل أن يسبقك أحد. وميزانيته عند الاستلام بين 500 ألف وميزانية البداية.', $c('league.code_length'))],
                ['How do I join a league?', 'join league friend code', sprintf('Ask your friend for their league\'s code (%d characters) and type it on the join page. You wait for the league owner\'s approval, then pick a team without a coach before anyone beats you to it. Its budget when you take it is between 500 thousand and the starting budget.', $c('league.code_length'))]),
            $t('vacation_league', ['league'], 'league',
                ['كيف آخذ إجازة من دوري؟', 'اجازة غياب دوري مسافر', sprintf('إجازة في دوري واحد (مرة في الموسم، حتى %d أيام) تحتاج سبباً يوافق عليه مسؤول الدوري. ولإجازة تشمل كل دورياتك بلا طلب: إجازة الحساب من «حسابي». والغائب بلا إجازة %d أيام قد يُطرد من الدوري.', $c('league.vacation_max_days'), $c('league.absence_days'))],
                ['How do I take a holiday from a league?', 'holiday vacation absence league away', sprintf('A holiday in one league (once a season, up to %d days) needs a reason the league\'s admin approves. For a holiday across all your leagues with no request: the account holiday in «My account». Someone away without a holiday for %d days may be removed from the league.', $c('league.vacation_max_days'), $c('league.absence_days'))]),
            // [Sprint 15 D1] The app on the phone.
            $t('app', ['home', 'profile'], 'profile',
                ['كيف أحمّل التطبيق على جوالي؟', 'تحميل تنزيل التطبيق اندرويد ايفون apk جوال', 'من صفحة «حمّل التطبيق» في الموقع (رابطها في أسفل كل صفحة): على أندرويد اضغط «نزّل التطبيق» ثم افتح الملف واسمح بالتثبيت إن سألك الجوال. وعلى آيفون افتح الموقع في Safari ثم زر المشاركة ثم «إضافة إلى الشاشة الرئيسية»، فتفتح اللعبة كتطبيق حتى يصل تطبيق App Store. وحسابك ودورياتك نفسها في الموقع والتطبيق.'],
                ['How do I get the app on my phone?', 'download app android iphone apk phone install', 'From the «Get the app» page of the site (its link is at the bottom of every page): on Android tap «Download the app», then open the file and allow installing if the phone asks. On the iPhone open the site in Safari, then Share, then «Add to Home Screen»: the game opens as an app until the App Store version comes. Your account and leagues are the same on the site and the app.']),
            // [Sprint 43 W1, W2] The contract with the club, and the store.
            $t('contract', ['club', 'league'], 'club',
                ['ما هو عقد تولي الفريق؟', 'عقد توقيع تولي الفريق الادارة', 'حين تبدأ موسماً مع فريقك يعرض عليك عقد تولي القيادة: ناديك ودوريك وموسمه، وهدف الإدارة، والمال المتاح للانتقالات. توقّعه بإصبعك مرة واحدة في الموسم، والتوقيع يُرسم على شاشتك فقط ولا يُرسل ولا يُحفظ.'],
                ['What is the coaching contract?', 'contract sign take over club board', 'When you start a season with your team, the board offers you its contract: your club, your league and its season, the board\'s objective and the money for transfers. You sign it with your finger once a season, and the signature is drawn on your screen only: it is never sent or kept.']),
            $t('store', ['store'], 'store',
                ['ما هي العروض والباقات؟', 'متجر عروض باقات شراء واتساب سعر خصم', 'في صفحة «العروض»: باقات ثابتة يضيفها فريق اللعبة، وعروض لمدة محددة تختفي وحدها بعد انتهائها. لكل واحد صورته وسعره (والسعر قبل الخصم إن وُجد). والطلب عبر واتساب: زر «اطلبه عبر واتساب» يفتح محادثة مع فريق اللعبة فيها اسم العرض ورقم حسابك. ولتصلك العروض بالبريد فعّلها من «حسابي» ← الإشعارات.'],
                ['What are the offers and packages?', 'store offers packages buy whatsapp price discount', 'On the «Offers» page: fixed packages the game\'s team adds, and offers for a set time that disappear when they end. Each has its picture and price (and the price before a discount, if any). You order by WhatsApp: «Order on WhatsApp» opens a chat with the game\'s team with the item and your account number. To get the offers by email, turn them on in My account, then Notifications.']),
            // [Sprint 43 C2] The creator never resigns; gone from the game, the league passes on.
            $t('league_creator', ['league'], 'league',
                ['ماذا يحدث إن غاب منشئ الدوري؟', 'منشئ الدوري غياب ترك نقل ادارة استقالة', sprintf('منشئ الدوري لا يستقيل منه لأنه يديره. وإن غاب عن اللعبة %d أيام أو حذف حسابه، تنتقل إدارة الدوري بالقرعة إلى أحد المدربين النشطين، ويُنشر بيان بذلك في أخبار الدوري. وإن لم يبقَ مدرب نشط يبقى منشئاً.', $c('league.absence_days'))],
                ['What happens if the league creator is gone?', 'league creator owner absent left handover resign', sprintf('The league creator cannot resign, since he runs it. If he is away from the game for %d days or deletes his account, the league passes by lot to one of its active coaches, and a statement says so in the league news. With no active coach left, he stays its creator.', $c('league.absence_days'))]),
            $t('vacation_account', ['profile'], 'profile',
                ['ما هي إجازة الحساب؟', 'اجازة الحساب كله حذف غياب', sprintf('إجازة لحسابك كله تحميه من الحذف: لا يُحسب غيابك في أي دوري، والمدرب المساعد يقود فرقك. حتى %d أيام تبدأ فوراً (مرتين في الموسم)، والأطول يراجعها فريق التطوير.', $c('account.auto_vacation_days'))],
                ['What is the account holiday?', 'account holiday vacation delete absence', sprintf('A holiday for your whole account protects it from deletion: your absence counts in no league, and the assistant coach runs your teams. Up to %d days start at once (twice a season); longer ones are reviewed by the development team.', $c('account.auto_vacation_days'))]),
            $t('alliance', ['league'], 'league',
                ['ما هي بطولة التحالفات؟', 'تحالف تحالفات بطولة فرق', 'تحالفان متساويان من فرق الدوري، من فريقين إلى عشرة في المجموع، يختارها منشئ الدوري من شاشة إنشائه: بالقرعة، أو يقسم المدربين بأسماء المستخدمين بنفسه. تتكوّن الفرق قبل الدور الأول بنصف ساعة من المدربين الذين انضموا، والأماكن الباقية بالقرعة أو للحاسوب، وتبدأ بعد اعتماد المطورين. وزملاء التحالف لا يتقابلون إلا إن لم يكن بد: حينها يختار المدربان من يكمل، وإن اختلفا يكمل الأقوى في موعد الدور، ومن يكمل يبادل حتى 3 لاعبين مع الفريق الآخر لاعباً مقابل لاعب مكافأةً للوصول.'],
                ['What is the alliance tournament?', 'alliance tournament teams', 'Two equal alliances of the league\'s teams, two to ten in all, chosen by the league\'s creator on its create screen: by draw, or splitting the coaches by username himself. The teams are formed half an hour before the first round from the coaches who joined; the places left go by draw or to the computer, and it starts once the developers approve it. Team-mates meet only when it cannot be helped: then the two coaches pick who goes on (if they differ, the stronger at the round\'s time), and the one who goes on may swap up to 3 players one for one with the other team as a reward.']),
            // [Sprint 29] The chat groups, the tournaments, the national teams and their draw.
            $t('groups', ['groups', 'home'], 'groups',
                ['ما هي الجروبات؟', 'جروب جروبات دردشة شات واتساب رسائل اصدقاء', 'الجروبات دردشة جماعية مثل واتساب داخل اللعبة. أنشئ جروباً وأضف أصدقاءك بأسماء المستخدمين، أو شارك رابطه فينضم من يفتحه. منشئ الجروب مشرف يضيف ويُخرج ويغيّر الاسم ويجعل غيره مشرفاً. اضغط أي رسالة لترد عليها أو تحذفها. وترسل صورة بزر الكاميرا، ورسالة صوتية بزر الميكروفون حين يكون مربع الكتابة فارغاً (حتى دقيقتين). وقد تحذف الإدارة الرسائل القديمة تلقائياً بعد أيام تحددها.'],
                ['What are the groups?', 'group groups chat whatsapp messages friends', 'Groups are group chats, like WhatsApp, inside the game. Make one and add your friends by their usernames, or share its link and whoever opens it joins. Its maker is an admin who adds, removes, renames and makes others admins. Tap any message to reply to it or delete it. Send a photo with the camera button, and a voice note with the microphone button while the text box is empty (up to two minutes). The admins may delete old messages automatically after some days.']),
            $t('league_group', ['groups', 'league'], 'groups',
                ['ما هو جروب الدوري؟', 'جروب الدوري البطولة مدربين دردشة', 'كل دوري وكل بطولة لهما جروب، أعضاؤه منشئه ومدربوه، ويتغيرون معه: من ينضم يدخل ومن يغادر يخرج. افتحه من صفحة الدوري.'],
                ['What is the league group?', 'league group tournament coaches chat', 'Every league and tournament has a group of its maker and its coaches, changing with them: whoever joins comes in, whoever leaves goes out. Open it from the league page.']),
            $t('tournaments', ['tournaments', 'leagues'], 'tournaments',
                ['كيف أنشئ بطولة؟', 'بطولة بطولات كاس العالم امم افريقيا اوروبا اسيا اندية مخصصة مجموعات خروج المغلوب', 'من «البطولات» ← «بطولة جديدة»: اختر قالباً (كأس العالم، أو كأس العالم للأندية، أو أمم أفريقيا أو أوروبا أو آسيا، أو بطولة مخصصة) فتُملأ الفرق والشكل، وعدّل ما تشاء: من فريقين حتى 32 من المنتخبات والأندية معاً. والنظام: دوري، أو مجموعات ثم إقصاء (1 أو 2 أو 4 أو 8 مجموعات، ويتأهل الأول أو الأولان)، أو خروج المغلوب. ينضم المدربون بكودها ويطلبون فريقاً كالدوري، ولا سوق فيها: كل فريق يلعب بقائمته. وتُدفع بالكوينز عند إنشائها: 20 لكل فريق. ويختار المنظم من يدرب الفرق: كل مدرب يطلب فريقاً، أو قرعة توزع الفرق على من يشارك (اضغط «شارك في البطولة»، وحين يكتمل العدد تُسحب بعد عشر دقائق)، أو يحدد هو صاحب كل فريق. ومن فريقين حتى 64.'],
                ['How do I make a tournament?', 'tournament world cup nations africa europe asia clubs custom groups knockout', 'From Tournaments, New tournament: pick a template (World Cup, Club World Cup, Africa, Europe or Asia, or custom) and the teams and shape fill in, then change what you like: two to 32 teams, national teams and clubs together. The format: a league, groups then a knockout (1, 2, 4 or 8 groups, the first one or two through), or a knockout. Coaches join with its code and ask for a team as in a league, and there is no market: every team plays with its squad. It is paid in coins when made: 20 for each team. The organizer chooses who coaches the teams: each coach asks for a team, a draw shares them among those who enter (tap Enter the tournament; once full it is drawn ten minutes later), or the organizer names each team\'s coach. From two teams up to 64.']),
            $t('national_teams', ['tournaments'], 'tournaments',
                ['من أين جاءت المنتخبات؟', 'منتخب منتخبات دولة جنسية لاعبين قائمة', 'كل منتخب من لاعبي جنسيته في البيانات: أفضل 23 (منهم 3 حراس). ويلعب المنتخب إن كان له 14 لاعباً وحارس على الأقل، والباقي يكمّله الأدمن من محرر البيانات. ولو اخترت نادياً ومنتخباً معاً بقي لاعب النادي مع ناديه وأخذ المنتخب من بعده.'],
                ['Where do the national teams come from?', 'national team nation country nationality players squad', 'Each national team is made from the players of its nationality in the data: its best 23 (three of them keepers). A country plays when it has at least 14 players and a keeper; the admin completes the rest in the data editor. If you pick a club and a national team together, the club keeps its players and the nation takes the next best.']),
            $t('tournament_draw', ['tournaments'], 'tournaments',
                ['كيف تعمل قرعة البطولة؟', 'قرعة البطولة مباشرة وعاء اعادة صوت', 'يحدد المنظم موعد قرعة مباشرة يشاهدها كل اللاعبين في نفس اللحظة: كرة تخرج من الوعاء، ثم يُكشف الفريق ويُنطق اسمه ويذهب إلى مجموعته. وفي المجموعات تُقسم الفرق أوعية بقوتها، وفي كل مجموعة فريق من كل وعاء. وبلا موعد تُسحب عند البداية، ومن فاتته يعيد مشاهدتها كما كانت بالضبط، ويتحقق منها ببصمتها المعلنة قبلها. وأثناءها دردشة مباشرة وتفاعلات بالإيموجي لكل المشاهدين، تُفتح قبلها بساعة وتُغلق بعدها بنصف ساعة، وتظهر في الإعادة في لحظتها.'],
                ['How does the tournament draw work?', 'tournament draw live pot replay sound', 'The organizer sets a live draw every player watches at the same moment: a ball leaves the bowl, the team is revealed, its name is said aloud, and it goes to its group. In groups the teams are split into pots by strength, one from each pot in every group. With no time set it is drawn at the start; whoever missed it replays it exactly as it was, and checks it against its fingerprint announced beforehand. During it everyone watching chats live and reacts with emoji, from an hour before to half an hour after, and a replay shows each at its moment.']),
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
            // [Sprint 28] The development ideas: suggestions, polls and the honour roll.
            $t('ideas', ['ideas', 'support', 'profile'], 'ideas',
                ['كيف أرسل اقتراحاً لتطوير اللعبة؟', 'اقتراح اقتراحات فكرة افكار ميزة جديدة تطوير تحسين اقترح مكافأة ذهب كوينز', sprintf('من «اقتراحات التطوير» (في حسابك وفي القائمة): اكتب عنواناً قصيراً وشرح فكرتك، فتصل لفريق التطوير (حتى %d اقتراحات في 24 ساعة). يرد الفريق على كل اقتراح: «أعجبنا» أو «نُفّذ في اللعبة» أو «لم يُعتمد» مع كلمة منه، ويصلك الرد في رسائلك. والاقتراح الذي يعجب الفريق قد يأخذ مكافأة كوينز (حتى %d) تصل محفظتك، ويضع اسمك في قائمة الشرف.', $c('ideas.per_day'), $c('ideas.reward_max'))],
                ['How do I send a suggestion to improve the game?', 'suggestion suggest idea ideas new feature improve reward coins gold', sprintf('From «Development ideas» (in your account and the menu): write a short title and explain your idea, and it reaches the development team (up to %d suggestions in 24 hours). The team answers each one: «We liked it», «Built into the game» or «Not taken», with a word from them, and the answer reaches your inbox. A suggestion the team likes may earn a coins reward (up to %d) in your wallet, and puts your name on the honour roll.', $c('ideas.per_day'), $c('ideas.reward_max'))]),
            $t('polls', ['ideas', 'home'], 'ideas',
                ['ما هو تصويت التطوير؟', 'تصويت تصويتات استفتاء صوت اصوت خيارات اولوية الميزة القادمة', sprintf('فريق التطوير يفتح تصويتاً لمدة محددة (حتى %d يوماً) بخيارات من الميزات المقترحة. لكل حساب صوت واحد يغيّره ما دام التصويت مفتوحاً، وترى النتائج بعد أن تصوّت، ويراها الجميع حين ينتهي. والخيار الأعلى أصواتاً يُضاف للعبة أو يأخذ أولوية التطوير.', $c('ideas.poll_max_days'))],
                ['What is a development poll?', 'poll polls vote voting options priority next feature', sprintf('The development team opens a poll for a set time (up to %d days) with options from the suggested features. Each account has one vote it can change while the poll is open; you see the results after you vote, and everyone sees them when it ends. The option with the most votes is added to the game or goes first in the work.', $c('ideas.poll_max_days'))]),
            $t('honour_roll', ['ideas'], 'ideas',
                ['ما هي قائمة الشرف للمساهمين؟', 'قائمة الشرف المساهمين ساهموا في تطوير اللعبة شكر اسمي', 'كل مدرب أعجب فريقَ التطوير اقتراحٌ منه يدخل قائمة الشرف في «اقتراحات التطوير»: اسمه، وعدد اقتراحاته المقبولة، والكوينز التي كسبها بها، وآخر اقتراح له. الأكثر مساهمة أولاً.'],
                ['What is the contributors\' honour roll?', 'honour roll honor contributors helped improve game thanks my name', 'Every coach with a suggestion the development team liked joins the honour roll in «Development ideas»: their name, how many suggestions were accepted, the coins they earned with them, and their latest one. The biggest contributors come first.']),

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
            // [Sprint 40 A1] The coach's own badges, their levels and coins.
            $t('badges', ['home'], null,
                ['ما أوسمتي ومكافآتها؟', 'وسام اوسمة اوسمتي مكافاة مكافأة كوينز مبتدئ متوسط محترف', sprintf('أوسمتك في الرئيسية تحت «المزيد»، بثلاثة مستويات: المبتدئ (أول فوز، 10 مباريات، 10 وديات، فكرة اعتُمدت، 3 أصدقاء)، والمتوسط (100 مباراة، 25 فوزاً، أول لقب، بطل الكأس، درجة المحترف)، والمحترف (بطل الدوري، درجة الأسطورة، 100 فوز، 5 ألقاب). كل وسام تبلغه يعطيك كوينز مرة واحدة: %d للمبتدئ، و%d للمتوسط، و%d للمحترف، وتصلك رسالة بها.', (int) $c('achievement_rewards.beginner'), (int) $c('achievement_rewards.intermediate'), (int) $c('achievement_rewards.pro'))],
                ['What are my badges and their rewards?', 'badge badges achievements reward coins beginner intermediate pro', sprintf('Your badges are on the home screen under «More», in three levels: beginner (first win, 10 matches, 10 friendlies, an idea accepted, 3 friends), intermediate (100 matches, 25 wins, first title, cup winner, professional tier) and pro (league champion, legend tier, 100 wins, 5 titles). Each badge you reach gives coins once: %d for a beginner one, %d intermediate, %d pro, with a message.', (int) $c('achievement_rewards.beginner'), (int) $c('achievement_rewards.intermediate'), (int) $c('achievement_rewards.pro'))]),
            $t('press_stakes', ['match'], 'match',
                ['ماذا يفعل تصريحي في المؤتمر الصحفي؟', 'مؤتمر صحفي تصريح وعد معنويات عواقب', 'يرفع معنويات لاعبيك في المباراة، ثم تحكم النتيجة عليه: الوعد بالفوز الكاسح يكافئك إن فزت ويكلفك إن خسرت، والهادئ آمن، والحماسي بينهما. وتظهر أرقام كل تصريح تحته.'],
                ['What does my press statement do?', 'press conference statement promise morale stakes', 'It lifts your players\' morale in the match, then the result judges it: promising a crushing win pays if you win and costs if you lose, the calm one is safe, the rallying one in between. Each statement shows its numbers under it.']),
            // [Sprint 33 Q1] The match's drawing tiers.
            $t('quality', ['match'], 'match',
                ['لماذا يبدو البث أخف على جوالي؟', 'اداء سلس متوازن كامل بطيء تقطيع جودة رسوم جوال ضعيف', 'زر «الأداء» في شاشة المباراة له ثلاث درجات: «سلس» للجوالات الضعيفة (رسوم أخف وجمهور أقل، بلا إعادة بطيئة للهدف)، و«متوازن» للجوالات المتوسطة، و«كامل» للجوالات القوية والكمبيوتر بكل المؤثرات. و«تلقائي» يختار حسب جهازك، وينزل درجة وحده إن بدأت الحركة تتقطع. والمباراة نفسها لا تتغير: الدرجة تغيّر الرسم فقط.'],
                ['Why does the broadcast look lighter on my phone?', 'performance smooth balanced full slow lag quality graphics weak phone', 'The match screen\'s «Performance» button has three tiers: «Smooth» for weak phones (lighter drawing, a smaller crowd, no slow-motion replay of the goal), «Balanced» for mid-range phones, and «Full» for strong phones and computers with every effect. «Auto» picks for your device and steps down by itself if the motion starts to stutter. The match itself never changes: the tier changes only the drawing.']),
        ];
    }
}
