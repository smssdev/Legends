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
            'timeline' => self::timeline($state, $timeline),
        ];
    }

    /** Each fact: a number, a short title and a sentence; weight > 0 favours $me. */
    private static function facts(array $me, array $them, int $gf, int $ga): array
    {
        $m = $me['stats'];
        $t = $them['stats'];
        $facts = [];

        $facts[] = ['weight' => ($m['presses_won'] - $t['presses_won']) * 3, 'big' => (string) $m['presses_won'], 'unit' => 'بناء مقطوع',
            'title' => $m['presses_won'] >= $t['presses_won'] ? 'ضغطك أفسد بناءهم' : 'ضغطهم أفسد بناءك',
            'text' => sprintf('قطعت %d من %d بناءً لهم، وقطعوا %d من %d بناءً لك.', $m['presses_won'], $t['builds'], $t['presses_won'], $m['builds'])];

        $facts[] = ['weight' => ($m['big_chances'] - $t['big_chances']) * 5, 'big' => $m['big_chances'].' / '.$t['big_chances'], 'unit' => 'فرص محققة',
            'title' => $m['big_chances'] >= $t['big_chances'] ? 'صنعت الفرص الأخطر' : 'فرصهم كانت أخطر',
            'text' => sprintf('فرص محققة: %d لك مقابل %d، وتسديدات %d مقابل %d.', $m['big_chances'], $t['big_chances'], $m['shots'], $t['shots'])];

        $expectedFor = intdiv($m['xg'], 100);
        $expectedAgainst = intdiv($t['xg'], 100);
        $luck = ($gf * 100 - $expectedFor) - ($ga * 100 - $expectedAgainst);
        $facts[] = ['weight' => intdiv($luck, 20), 'big' => sprintf('%d.%d', intdiv($expectedFor, 100), intdiv($expectedFor % 100, 10)), 'unit' => 'أهداف متوقعة',
            'title' => abs($luck) < 60 ? 'النتيجة تعكس المباراة' : ($luck > 0 ? 'الحظ والفعالية معك' : 'الحظ لم يكن معك'),
            'text' => sprintf('فرصك كانت تساوي حوالي %d.%d هدف وسجلت %d، وفرصهم حوالي %d.%d وسجلوا %d.',
                intdiv($expectedFor, 100), intdiv($expectedFor % 100, 10), $gf, intdiv($expectedAgainst, 100), intdiv($expectedAgainst % 100, 10), $ga)];

        $facts[] = ['weight' => ($m['counters'] - $t['counters']) * 3, 'big' => (string) $m['counters'], 'unit' => 'هجمات مرتدة',
            'title' => $m['counters'] >= $t['counters'] ? 'ارتداداتك فاجأتهم' : 'ارتداداتهم أتعبتك',
            'text' => sprintf('هجمات مرتدة: %d لك مقابل %d.', $m['counters'], $t['counters'])];

        $fitMe = self::fitness($me);
        $fitThem = self::fitness($them);
        $facts[] = ['weight' => intdiv($fitMe - $fitThem, 150), 'big' => intdiv($fitMe, 100).'%', 'unit' => 'لياقة في النهاية',
            'title' => $fitMe >= $fitThem ? 'أنهيت المباراة أنشط منهم' : 'الإرهاق أثّر عليك',
            'text' => sprintf('متوسط اللياقة في النهاية: %d%% لك مقابل %d%%.', intdiv($fitMe, 100), intdiv($fitThem, 100))];

        $facts[] = ['weight' => ($t['red'] - $m['red']) * 12 + ($t['yellow'] - $m['yellow']), 'big' => (string) ($m['yellow'] + $m['red']), 'unit' => 'بطاقات',
            'title' => $m['red'] > $t['red'] ? 'الطرد كلّفك' : ($t['red'] > $m['red'] ? 'لعبت بأفضلية عددية' : 'الانضباط'),
            'text' => sprintf('بطاقات: %d صفراء و%d حمراء لك، مقابل %d و%d.', $m['yellow'], $m['red'], $t['yellow'], $t['red'])];

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
            $lines[] = ['tag' => 'ممتاز', 'text' => 'خلق الفريق فرصاً أخطر من الخصم.'];
        }
        if ($m['builds'] > 0 && $m['builds'] < $m['builds_lost'] * 4) {
            $lines[] = ['tag' => 'مطلوب', 'text' => 'نفقد الكرة كثيراً في بداية البناء. جرّب إيقاعاً أهدأ أو كرات طويلة.'];
        }
        if ($m['red'] > 0) {
            $lines[] = ['tag' => 'مطلوب', 'text' => 'الطرد غيّر المباراة. قطع الكرة الأخف يقلل البطاقات.'];
        }
        if (! $lines) {
            $lines[] = ['tag' => $result === 'loss' ? 'مطلوب' : 'ممتاز', 'text' => $result === 'loss' ? 'المباراة كانت متقاربة، والتفاصيل حسمتها.' : 'أداء متوازن في كل الخطوط.'];
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
