<?php

namespace App\Messages;

/**
 * A message's words [Sprint 22 B1]: its title, its text and where it leads, from its type and payload, in
 * Arabic. One place for the web and the app; a new type adds its case here.
 */
class MessageText
{
    public const TYPES = ['referee', 'absence_warning', 'left_absent', 'kicked', 'join_request', 'join_approved', 'join_rejected', 'match_report', 'in_debt', 'forced_sale'];

    private const STRICTNESS = ['lenient' => 'متساهل', 'medium' => 'متوسط', 'strict' => 'صارم'];

    private const RESULT = ['win' => 'فزت', 'draw' => 'تعادلت', 'loss' => 'خسرت'];

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
            default => ['title' => 'رسالة', 'body' => '', 'link' => null],
        };
    }
}
