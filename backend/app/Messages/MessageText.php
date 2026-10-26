<?php

namespace App\Messages;

/**
 * A message's words [Sprint 22 B1]: its title, its text and where it leads, from its type and payload, in
 * Arabic. One place for the web and the app; a new type adds its case here.
 */
class MessageText
{
    public const TYPES = ['referee', 'absence_warning', 'left_absent', 'kicked', 'join_request', 'join_approved', 'join_rejected', 'match_report', 'in_debt', 'forced_sale', 'offer_received', 'offer_countered', 'offer_accepted', 'offer_rejected', 'offer_cancelled', 'offer_expired', 'scout_report', 'training_done', 'camp_back', 'stadium_part', 'season_end', 'vacation_request', 'vacation_approved', 'vacation_rejected', 'listing_sold', 'announcement', 'staff_left', 'match_of_day'];

    private const STRICTNESS = ['lenient' => 'متساهل', 'medium' => 'متوسط', 'strict' => 'صارم'];

    private const SECTION = ['seats' => 'التذاكر والمقاعد', 'pitch' => 'أرضية الملعب', 'training' => 'منشأة التدريب'];

    private const RESULT = ['win' => 'فزت', 'draw' => 'تعادلت', 'loss' => 'خسرت'];

    /** The staff's names [X20]. */
    public const STAFF = ['att_coach' => 'مدرب الهجوم', 'mid_coach' => 'مدرب الوسط', 'def_coach' => 'مدرب الدفاع', 'keeper_coach' => 'مدرب الحراس',
        'physio' => 'المعالج البدني', 'doctor' => 'طبيب النادي', 'lawyer' => 'محامي النادي', 'mental_coach' => 'المعد النفسي'];

    /** An offer in a sentence: who, for whom, with what. */
    private static function offer(string $type, array $p): string
    {
        $wants = implode(' و', $p['in'] ?? []);
        $gives = array_filter([($p['money'] ?? 0) > 0 ? number_format($p['money']) : null, ($p['out'] ?? []) ? implode(' و', $p['out']) : null]);
        $deal = sprintf('%s على %s مقابل %s', $p['from'] ?? '', $wants, $gives ? implode(' و', $gives) : 'لا شيء');

        return match ($type) {
            'offer_received' => "عرض من {$deal}.",
            'offer_countered' => "رد {$p['from']} بعرض مقابل: {$deal}.",
            'offer_accepted' => "قبل {$p['to']} عرضك على {$wants}، وتمت الصفقة.",
            'offer_rejected' => "رفض {$p['to']} عرضك على {$wants}.",
            'offer_cancelled' => "أُلغي عرض {$deal}: أحد لاعبيه انتقل أو سُحب العرض.",
            default => "انتهت مدة عرض {$deal} بلا رد.",
        };
    }

    /** @return array{title: string, body: string, link: ?string} */
    public static function render(string $type, array $p): array
    {
        $league = $p['league'] ?? '';

        return match ($type) {
            'referee' => [
                'title' => 'حكم مباراتك القادمة',
                'body' => sprintf('حكم مباراتك أمام %s في %s %s. %s', $p['opponent'] ?? '', $league, self::STRICTNESS[$p['strictness'] ?? 'medium'] ?? '',
                    ($p['strictness'] ?? '') === 'strict' ? 'الحكم الصارم يكثر من البطاقات، فراجع قطع الكرة قبل القفل.' : 'راجع تشكيلتك وتكتيكك قبل القفل.'),
                'link' => '/match',
            ],
            'absence_warning' => [
                'title' => 'لم نرك منذ مدة',
                'body' => sprintf('لم تدخل دوري %s منذ %d ساعة. إن غبت حتى تكمل %d أيام يعود فريقك للحاسوب. ادخل الدوري أو خذ إجازة.',
                    $league, (int) config('game.league.absence_warning_hours'), (int) config('game.league.absence_days')),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}" : '/leagues',
            ],
            'left_absent' => [
                'title' => 'خرجت من الدوري بسبب الغياب',
                'body' => sprintf('غبت عن دوري %s %d أيام، فعاد فريقك %s للحاسوب. يمكنك العودة إلى هذا الدوري في الموسم الجديد.',
                    $league, (int) config('game.league.absence_days'), $p['club'] ?? ''),
                'link' => '/leagues',
            ],
            'kicked' => [
                'title' => 'طُردت من الدوري',
                'body' => sprintf('طردك منشئ دوري %s، والسبب: «%s». عاد فريقك %s للحاسوب.', $league, $p['reason'] ?? '', $p['club'] ?? ''),
                'link' => '/leagues',
            ],
            'join_request' => [
                'title' => 'طلب انضمام جديد',
                'body' => sprintf('%s يطلب الانضمام إلى دوري %s.', $p['user'] ?? '', $league),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}" : '/leagues',
            ],
            'join_approved' => [
                'title' => 'قُبل طلبك',
                'body' => sprintf('قبل منشئ دوري %s طلبك. اختر فريقك الآن.', $league),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}/pick" : '/leagues',
            ],
            'join_rejected' => [
                'title' => 'لم يُقبل طلبك',
                'body' => sprintf('رفض منشئ دوري %s طلب انضمامك.', $league),
                'link' => '/leagues',
            ],
            'match_report' => [
                'title' => 'تقرير مباراتك جاهز',
                'body' => sprintf('%s أمام %s %s. اقرأ لماذا في التقرير.', self::RESULT[$p['result'] ?? 'draw'] ?? '', $p['opponent'] ?? '', $p['score'] ?? ''),
                'link' => isset($p['match_id']) ? "/live/{$p['match_id']}/report" : null,
            ],
            'in_debt' => [
                'title' => 'رصيد ناديك تحت الصفر',
                'body' => sprintf('رصيد %s صار %s بعد الرواتب، ولا يمكنك الصرف حتى يعود موجباً. إن بقي سالباً %d جولات متتالية يُباع أغلى لاعب تلقائياً.',
                    $p['club'] ?? '', number_format((int) ($p['balance'] ?? 0)), (int) ($p['rounds'] ?? 3)),
                'link' => '/finance',
            ],
            'forced_sale' => [
                'title' => 'بيع إجباري بسبب الدين',
                'body' => sprintf('بقي رصيد %s سالباً %d جولات، فبيع للمجموعة: %s.', $p['club'] ?? '', (int) ($p['rounds'] ?? 3), implode('، ', $p['players'] ?? [])),
                'link' => '/finance',
            ],
            'offer_received', 'offer_countered', 'offer_accepted', 'offer_rejected', 'offer_cancelled', 'offer_expired' => [
                'title' => ['offer_received' => 'عرض جديد', 'offer_countered' => 'رد بعرض مقابل', 'offer_accepted' => 'قُبل عرضك',
                    'offer_rejected' => 'رُفض عرضك', 'offer_cancelled' => 'أُلغي عرض', 'offer_expired' => 'انتهت مدة عرض'][$type],
                'body' => self::offer($type, $p),
                'link' => '/market?tab=offers',
            ],
            'scout_report' => [
                'title' => 'تقرير الكشاف جاهز',
                'body' => ($p['players'] ?? []) ? 'وجد لك الكشاف: '.implode('، ', $p['players']).'. اشترهم قبل تجديد المجموعة.'
                    : 'لم يجد الكشاف لاعباً بهذه المعايير، فرُد لك المبلغ كاملاً.',
                'link' => '/scout',
            ],
            'training_done' => [
                'title' => 'اكتمل تدريب '.$p['player'],
                'body' => sprintf('تحسن %s فأصبحت قوته %d، وخانته فارغة الآن: اختر لاعباً آخر للتدريب.', $p['player'], $p['overall']),
                'link' => '/training',
            ],
            'camp_back' => [
                'title' => 'عاد اللاعبون من المعسكر',
                'body' => implode('، ', array_map(fn ($x) => $x['gain'] ? "{$x['name']} +{$x['gain']}" : "{$x['name']} بلا زيادة", $p['players'] ?? [])).'. ومن لم تكتمل قفزته يحتفظ بتقدمه.',
                'link' => '/training',
            ],
            'stadium_part' => [
                'title' => ($p['stage_done'] ?? false) ? 'اكتملت مرحلة في الملعب' : 'اكتمل جزء في الملعب',
                'body' => sprintf('%s: %s. ابدأ الجزء التالي من صفحة الملعب.', self::SECTION[$p['section']] ?? '',
                    ($p['stage_done'] ?? false) ? "المرحلة {$p['stage']} مكتملة وأثرها يعمل الآن" : "الجزء {$p['part']} من 5 في المرحلة {$p['stage']}"),
                'link' => '/stadium',
            ],
            'season_end' => [
                'title' => ($p['champion'] ?? false) ? "بطل {$p['league']}!" : "انتهى الموسم {$p['season']} في {$p['league']}",
                'body' => sprintf('أنهيت في المركز %d. هدف الدوري: %s، وهدف الكأس: %s. %s', $p['place'],
                    ($p['league_goal'] ?? false) ? 'تحقق' : 'لم يتحقق', ($p['cup_goal'] ?? false) ? 'تحقق' : 'لم يتحقق',
                    ($p['renew'] ?? false) ? 'بدأ الموسم الجديد من الصفر، وفريقك ينتظرك في فترة الإعداد.' : 'وانتهى الدوري.'),
                'link' => '/league',
            ],
            'vacation_request' => [
                'title' => 'طلب إجازة في '.$league,
                'body' => sprintf('%s يطلب إجازة %d أيام في %s. السبب: %s. وافق أو ارفض من صفحة الدوري.', $p['coach'] ?? '', (int) ($p['days'] ?? 0), $league, $p['reason'] ?? ''),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}" : '/leagues',
            ],
            'vacation_approved' => [
                'title' => 'وافق مسؤول الدوري على إجازتك',
                'body' => sprintf('إجازتك في %s %d أيام بدأت الآن. لا يُحسب غيابك، والمساعد يدير فريقك.', $league, (int) ($p['days'] ?? 0)),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}" : '/leagues',
            ],
            'vacation_rejected' => [
                'title' => 'رُفض طلب إجازتك',
                'body' => sprintf('رفض مسؤول %s طلب إجازتك. يمكنك أن تطلبها من جديد بسبب أوضح، أو تأخذ إجازة لحسابك كله من صفحة حسابك.', $league),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}" : '/leagues',
            ],
            'listing_sold' => [
                'title' => 'بِيع '.($p['player'] ?? 'لاعبك'),
                'body' => sprintf('اشترى نادٍ من خارج الدوري %s بالسعر الذي طلبته: %s. المبلغ في رصيد ناديك.', $p['player'] ?? '', number_format((int) ($p['price'] ?? 0))),
                'link' => '/finance',
            ],
            // A staff contract ended without a renewal [X20].
            // The night's big match of a round in two slots [X31].
            'match_of_day' => [
                'title' => 'قمة الجولة الليلة',
                'body' => sprintf('الليلة في سهرة %s: قمة الجولة بين %s و%s. احجز تذكرتك وشاهد اللقاء مباشرة!', $league, $p['home'] ?? '', $p['away'] ?? ''),
                'link' => '/match',
            ],
            'staff_left' => [
                'title' => 'استقال '.(self::STAFF[$p['type'] ?? ''] ?? 'أحد الطاقم'),
                'body' => sprintf('انتهى عقد %s (%d نجوم) ولم يُجدَّد، فغادر النادي. يمكنك التعاقد مع غيره من صفحة الطاقم.', self::STAFF[$p['type'] ?? ''] ?? 'الأخصائي', (int) ($p['stars'] ?? 0)),
                'link' => '/specialists',
            ],
            // From the game's developers, with the official badge [X11].
            'announcement' => [
                'title' => (string) ($p['title'] ?? 'إعلان من فريق GLM'),
                'body' => (string) ($p['body'] ?? ''),
                'link' => null,
                'sender' => ['name' => (string) ($p['from'] ?? ''), 'username' => (string) ($p['username'] ?? ''), 'official' => true],
            ],
            default => ['title' => 'رسالة', 'body' => '', 'link' => null],
        };
    }
}
