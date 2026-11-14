<?php

namespace App\Simulator;

/**
 * Post-match report (docs/ENGINE.md 8.1): the top reasons for the result in
 * plain Arabic, one thing to improve, ratings, man of the match, thirds and
 * momentum. Built only from the match stats and events, from one side's view.
 */
class Report
{
    public static function build(array $state, array $timeline, string $side = 'home'): array
    {
        $other = $side === 'home' ? 'away' : 'home';
        $me = $state['teams'][$side];
        $them = $state['teams'][$other];
        $gf = $state['score'][$side];
        $ga = $state['score'][$other];
        if ($state['shootout']) {
            $gf += $state['shootout'][$side] > $state['shootout'][$other] ? 1 : 0;
            $ga += $state['shootout'][$other] > $state['shootout'][$side] ? 1 : 0;
        }
        $result = $gf > $ga ? 'win' : ($gf < $ga ? 'loss' : 'draw');

        $facts = self::facts($me, $them, $state['score'][$side], $state['score'][$other]);
        usort($facts, fn ($a, $b) => abs($b['weight']) <=> abs($a['weight']));
        $good = array_values(array_filter($facts, fn ($f) => $f['weight'] > 0));
        $bad = array_values(array_filter($facts, fn ($f) => $f['weight'] < 0));
        $reasons = $result === 'loss' ? array_slice($bad, 0, 3) : array_slice($good, 0, 3);
        // An even match leans neither way: its most telling facts, the neutral ones first, so a report always explains.
        if (! $reasons) {
            $even = array_values(array_filter($facts, fn ($f) => $result === 'loss' ? $f['weight'] <= 0 : $f['weight'] >= 0));
            $reasons = array_slice($even ?: $facts, 0, 3);
        }
        $improve = $result === 'loss' ? ($good[0] ?? null) : ($bad[0] ?? null);

        $ratings = [];
        $motm = null;
        foreach (['home', 'away'] as $t) {
            foreach ($state['teams'][$t]['players'] as $p) {
                if ($p['on'] || $p['out'] !== '') {
                    $row = ['team' => $t, 'id' => $p['id'], 'name' => $p['name'], 'no' => $p['no'], 'rating' => $p['st']['r'],
                        'goals' => $p['st']['goals'], 'assists' => $p['st']['assists'], 'shots' => $p['st']['shots']];
                    $ratings[$t][] = $row;
                    if ($motm === null || $row['rating'] > $motm['rating']) {
                        $motm = $row;
                    }
                }
            }
            usort($ratings[$t], fn ($a, $b) => $b['rating'] <=> $a['rating']);
        }

        $thirds = $state['thirds'];
        $total = max(1, array_sum($thirds));

        return [
            'result' => $result,
            'score' => $state['score'],
            'shootout' => $state['shootout'],
            'reasons' => array_map(fn ($f) => array_diff_key($f, ['weight' => 1]), $reasons),
            'improve' => $improve ? array_diff_key($improve, ['weight' => 1]) : null,
            'verdict' => self::verdict($me, $them, $result),
            'man_of_the_match' => $motm,
            'ratings' => $ratings,
            'stats' => ['home' => $state['teams']['home']['stats'], 'away' => $state['teams']['away']['stats']],
            'thirds' => array_map(fn ($v) => intdiv($v * 100, $total), $thirds),
            'momentum' => $state['momentum'],
            // [Sprint 30 G5] «خطتك ضد خطته»: the shapes as they ended (seen on the pitch by both, never the tactics).
            'formations' => ['home' => $state['teams']['home']['formation'] ?? null, 'away' => $state['teams']['away']['formation'] ?? null],
            'timeline' => self::timeline($state, $timeline),
        ];
    }

    /**
     * Each fact: a number, a short title and a sentence; weight > 0 favours $me. [Sprint 64 B6] And where a coach acts on
     * it (go: the lineup or the tactics; none for luck), so the report's one suggestion (improve) has its button.
     */
    private static function facts(array $me, array $them, int $gf, int $ga): array
    {
        $m = $me['stats'];
        $t = $them['stats'];
        $facts = [];

        $facts[] = ['go' => 'tactics', 'weight' => ($m['presses_won'] - $t['presses_won']) * 3, 'big' => (string) $m['presses_won'], 'unit' => __('بناء مقطوع'),
            'title' => $m['presses_won'] >= $t['presses_won'] ? __('قطعت بناءهم كثيراً') : __('بناؤك قُطع كثيراً'),
            'text' => sprintf(__('قطعت %d من %d بناءً لهم، وقطعوا %d من %d بناءً لك.'), $m['presses_won'], $t['builds'], $t['presses_won'], $m['builds'])];

        $facts[] = ['go' => 'lineup', 'weight' => ($m['big_chances'] - $t['big_chances']) * 5, 'big' => $m['big_chances'].' / '.$t['big_chances'], 'unit' => __('فرص محققة'),
            'title' => $m['big_chances'] >= $t['big_chances'] ? __('صنعت الفرص الأخطر') : __('فرصهم كانت أخطر'),
            'text' => sprintf(__('فرص محققة: %d لك مقابل %d، وتسديدات %d مقابل %d.'), $m['big_chances'], $t['big_chances'], $m['shots'], $t['shots'])];

        $expectedFor = intdiv($m['xg'], 100);
        $expectedAgainst = intdiv($t['xg'], 100);
        $luck = ($gf * 100 - $expectedFor) - ($ga * 100 - $expectedAgainst);
        $facts[] = ['go' => null, 'weight' => intdiv($luck, 20), 'big' => sprintf('%d.%d', intdiv($expectedFor, 100), intdiv($expectedFor % 100, 10)), 'unit' => __('أهداف متوقعة'),
            'title' => abs($luck) < 60 ? __('النتيجة تعكس المباراة') : ($luck > 0 ? __('الحظ والفعالية معك') : __('الحظ لم يكن معك')),
            'text' => sprintf(__('فرصك كانت تساوي حوالي %d.%d هدف وسجلت %d، وفرصهم حوالي %d.%d وسجلوا %d.'),
                intdiv($expectedFor, 100), intdiv($expectedFor % 100, 10), $gf, intdiv($expectedAgainst, 100), intdiv($expectedAgainst % 100, 10), $ga)];

        $facts[] = ['go' => 'tactics', 'weight' => ($m['counters'] - $t['counters']) * 3, 'big' => (string) $m['counters'], 'unit' => __('هجمات مرتدة'),
            'title' => $m['counters'] >= $t['counters'] ? __('ارتداداتك فاجأتهم') : __('ارتداداتهم أتعبتك'),
            'text' => sprintf(__('هجمات مرتدة: %d لك مقابل %d.'), $m['counters'], $t['counters'])];

        $fitMe = self::fitness($me);
        $fitThem = self::fitness($them);
        $facts[] = ['go' => 'training', 'weight' => intdiv($fitMe - $fitThem, 150), 'big' => intdiv($fitMe, 100).'%', 'unit' => __('لياقة في النهاية'),
            'title' => $fitMe >= $fitThem ? __('أنهيت المباراة أنشط منهم') : __('الإرهاق أثّر عليك'),
            'text' => sprintf(__('متوسط اللياقة في النهاية: %d%% لك مقابل %d%%.'), intdiv($fitMe, 100), intdiv($fitThem, 100))];

        $facts[] = ['go' => 'tactics', 'weight' => ($t['red'] - $m['red']) * 12 + ($t['yellow'] - $m['yellow']), 'big' => (string) ($m['yellow'] + $m['red']), 'unit' => __('بطاقات'),
            'title' => $m['red'] > $t['red'] ? __('الطرد كلّفك') : ($t['red'] > $m['red'] ? __('لعبت بأفضلية عددية') : __('الانضباط')),
            'text' => sprintf(__('بطاقات: %d صفراء و%d حمراء لك، مقابل %d و%d.'), $m['yellow'], $m['red'], $t['yellow'], $t['red'])];

        return $facts;
    }

    private static function fitness(array $team): int
    {
        $on = array_filter($team['players'], fn ($p) => $p['on']);

        return $on ? intdiv(array_sum(array_column($on, 'fit')), count($on)) : 0;
    }

    private static function verdict(array $me, array $them, string $result): array
    {
        $m = $me['stats'];
        $lines = [];
        if ($m['big_chances'] > $them['stats']['big_chances']) {
            $lines[] = ['tag' => __('ممتاز'), 'text' => __('خلق الفريق فرصاً أخطر من الخصم.')];
        }
        if ($m['builds'] > 0 && $m['builds'] < $m['builds_lost'] * 4) {
            $lines[] = ['tag' => __('مطلوب'), 'text' => __('نفقد الكرة كثيراً في بداية البناء. جرّب إيقاعاً أهدأ أو كرات طويلة.')];
        }
        if ($m['red'] > 0) {
            $lines[] = ['tag' => __('مطلوب'), 'text' => __('الطرد غيّر المباراة. قطع الكرة الأخف يقلل البطاقات.')];
        }
        if (! $lines) {
            $lines[] = ['tag' => $result === 'loss' ? __('مطلوب') : __('ممتاز'), 'text' => $result === 'loss' ? __('المباراة كانت متقاربة، والتفاصيل حسمتها.') : __('أداء متوازن في كل الخطوط.')];
        }

        return $lines;
    }

    private static function timeline(array $state, array $ticks): array
    {
        $rows = [];
        foreach ($ticks as $tick) {
            foreach ($tick['events'] as $e) {
                if (in_array($e['type'], ['goal', 'card', 'sub', 'injury', 'penalty'], true)) {
                    $rows[] = ['minute' => $tick['minute'], 'period' => $tick['period']] + $e;
                }
            }
        }

        return $rows;
    }
}
