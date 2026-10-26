<?php

namespace App\League;

/**
 * The assistant's live reading [ENGINE 8.2, PLAN 2.24, Sprint 20 B2]: a short note to one coach, on his club's
 * private channel, about every 15 minutes of play or at once after a big moment (a goal, a red card, a line of
 * his falling under 60% fitness). It describes what the match shows, from MatchFacts only (the public events
 * and his own side), and gives no order: the decision stays his.
 */
class Readings
{
    /**
     * The reading due after this minute, or null. $said: what this side was told so far ([kind => tick] and
     * 'last' => the minute of the last one), so a note is not repeated and a quiet match is not chattered over.
     *
     * @return array{0: ?array, 1: array}
     */
    public static function next(array $facts, array $events, array $said, string $locale = 'ar'): array
    {
        self::$en = $locale === 'en';
        $side = $facts['side'];
        $minute = $facts['minute'];
        $every = (int) config('game.matches.reading_minutes');
        $big = self::bigMoment($facts, $events, $said);
        if (! $big && $minute - ($said['last'] ?? 0) < $every) {
            return [null, $said];
        }
        $notes = $big ? [$big] : self::notes($facts);
        $notes = array_values(array_filter($notes, fn ($n) => ($said[$n['kind']] ?? -99) < $minute - $every * 2 || ($n['big'] ?? false)));
        usort($notes, fn ($a, $b) => $b['weight'] <=> $a['weight']);
        $note = $notes[0] ?? null;
        $said['last'] = $minute;
        if (! $note) {
            return [null, $said];
        }
        $said[$note['kind']] = $minute;
        if ($note['kind'] === 'tired') {
            $said['tired_'.$note['line']] = true;
        }

        return [['tick' => $facts['tick'], 'minute' => $minute, 'side' => $side, 'kind' => $note['kind'], 'text' => $note['text']], $said];
    }

    /** A goal, a red card, or a line of his under the fitness mark in this minute. */
    private static function bigMoment(array $facts, array $events, array $said): ?array
    {
        $side = $facts['side'];
        $me = $facts['teams'][$side];
        $them = $facts['teams'][$side === 'home' ? 'away' : 'home'];
        $m = $me['stats'];
        $t = $them['stats'];
        foreach ($events as $e) {
            if ($e['type'] === 'goal') {
                $ours = $e['team'] === $side;
                $text = $ours
                    ? ($m['big_chances'] > $t['big_chances']
                        ? sprintf(self::say('هدف! وهو نتيجة طبيعية: صنعنا %s مقابل %d لهم.', 'Goal! And a natural one: we made %s against %d for them.'), self::count($m['big_chances'], self::CHANCES), $t['big_chances'])
                        : sprintf(self::say('سجلنا من %s فقط، والفعالية معنا اليوم.', 'We scored from only %s, and our finishing is sharp today.'), self::count($m['shots'], self::SHOTS)))
                    : ($t['counters'] > 0 && $t['counters'] >= $m['counters']
                        ? sprintf(self::say('استقبلنا هدفاً. هجماتهم المرتدة وصلت %s حتى الآن.', 'We conceded. Their counters have reached us %s so far.'), self::count($t['counters'], self::TIMES))
                        : sprintf(self::say('استقبلنا هدفاً. سددوا على مرمانا %s مقابل %d لنا.', 'We conceded. They shot at our goal %s against %d for us.'), self::count($t['shots'], self::TIMES), $m['shots']));

                return ['kind' => $ours ? 'goal_for' : 'goal_against', 'weight' => 100, 'big' => true, 'text' => $text];
            }
            if ($e['type'] === 'card' && ($e['color'] ?? '') === 'red') {
                $ours = $e['team'] === $side;

                return ['kind' => $ours ? 'red_for' : 'red_against', 'weight' => 90, 'big' => true, 'text' => $ours
                    ? self::say('نلعب بعشرة الآن. كل خط سيتعب أسرع، وتبديل في الوسط قد يعيد التوازن.', 'We are down to ten. Every line will tire faster, and a midfield change may restore the balance.')
                    : self::say('يلعبون بعشرة الآن. لدينا لاعب زائد في الملعب.', 'They are down to ten. We have an extra player on the pitch.')];
            }
        }
        foreach (self::lines($me) as $line => $fit) {
            if ($fit < 60 && ! isset($said['tired_'.$line])) {
                return ['kind' => 'tired', 'line' => $line, 'weight' => 80, 'big' => true,
                    'text' => sprintf(self::say('لياقة %s نزلت إلى %d%%. اللاعب المتعب يخسر الصراعات أكثر.', 'Our %s\'s fitness fell to %d%%. A tired player loses more duels.'), self::line($line), $fit)];
            }
        }

        return null;
    }

    private const LINE_NAMES = ['def' => 'الدفاع', 'mid' => 'الوسط', 'att' => 'الهجوم'];

    private const LINE_NAMES_EN = ['def' => 'defence', 'mid' => 'midfield', 'att' => 'attack'];

    /** [UP2] The note in the coach's language: set by next() for its call. */
    private static bool $en = false;

    private static function say(string $ar, string $en): string
    {
        return self::$en ? $en : $ar;
    }

    private static function line(string $line): string
    {
        return (self::$en ? self::LINE_NAMES_EN : self::LINE_NAMES)[$line];
    }

    /** The same counted nouns in English: [one, many]. */
    private const EN = [self::CHANCES[3] => ['clear chance', 'clear chances'], self::SHOTS[3] => ['shot', 'shots'], self::TIMES[3] => ['time', 'times'], self::CARDS[3] => ['booking', 'bookings']];

    // A counted noun as Arabic says it: one, two, three to ten, eleven and more.
    private const CHANCES = ['فرصة محققة واحدة', 'فرصتين محققتين', 'فرص محققة', 'فرصة محققة'];

    private const SHOTS = ['تسديدة واحدة', 'تسديدتين', 'تسديدات', 'تسديدة'];

    private const TIMES = ['مرة واحدة', 'مرتين', 'مرات', 'مرة'];

    private const CARDS = ['إنذار واحد', 'إنذاران', 'إنذارات', 'إنذاراً'];

    private static function count(int $n, array $forms): string
    {
        if (self::$en) {
            $en = self::EN[$forms[3]];

            return $n === 1 ? ($forms === self::TIMES ? 'once' : "one {$en[0]}") : ($forms === self::TIMES && $n === 2 ? 'twice' : "{$n} {$en[1]}");
        }

        return match (true) {
            $n === 1 => $forms[0],
            $n === 2 => $forms[1],
            $n >= 3 && $n <= 10 => "{$n} {$forms[2]}",
            default => "{$n} {$forms[3]}",
        };
    }

    /** The things worth saying now, each with how much it matters. */
    private static function notes(array $facts): array
    {
        $side = $facts['side'];
        $m = $facts['teams'][$side]['stats'];
        $t = $facts['teams'][$side === 'home' ? 'away' : 'home']['stats'];
        $notes = [];
        if ($m['builds_lost'] >= 3 && $m['builds'] <= $m['builds_lost'] * 3) {
            $notes[] = ['kind' => 'build_lost', 'weight' => 40 + $m['builds_lost'] * 3,
                'text' => sprintf(self::say('نفقد الكرة كثيراً في بداية البناء (%d من %d).', 'We lose the ball a lot early in the build-up (%d of %d).'), $m['builds_lost'], $m['builds'])];
        }
        if ($m['presses_won'] >= 3 && $m['presses_won'] > $t['presses_won']) {
            $notes[] = ['kind' => 'press_won', 'weight' => 30 + $m['presses_won'] * 3,
                'text' => sprintf(self::say('نستعيد الكرة مبكراً في ملعبهم (%s).', 'We win the ball back early in their half (%s).'), self::count($m['presses_won'], self::TIMES))];
        }
        if ($m['big_chances'] >= 2 && $m['big_chances'] > $m['goals'] * 3) {
            $notes[] = ['kind' => 'finishing', 'weight' => 35 + $m['big_chances'] * 5,
                'text' => sprintf(self::say('صنعنا %s وسجلنا %d. الفرص موجودة، والهدف سيأتي.', 'We made %s and scored %d. The chances are there, and the goal will come.'), self::count($m['big_chances'], self::CHANCES), $m['goals'])];
        }
        if ($t['big_chances'] >= 2 && $t['big_chances'] > $m['big_chances']) {
            $notes[] = ['kind' => 'danger', 'weight' => 35 + $t['big_chances'] * 5,
                'text' => sprintf(self::say('وصلوا إلى %s أمام مرمانا مقابل %d لنا.', 'They got %s in front of our goal against %d for us.'), self::count($t['big_chances'], self::CHANCES), $m['big_chances'])];
        }
        if ($t['counters'] >= 3 && $t['counters'] > $m['counters']) {
            $notes[] = ['kind' => 'counters_against', 'weight' => 30 + $t['counters'] * 4,
                'text' => sprintf(self::say('هجماتهم المرتدة تصل إلينا (%s). مساحات خلف خطنا.', 'Their counters are reaching us (%s). There is space behind our line.'), self::count($t['counters'], self::TIMES))];
        }
        if ($m['counters'] >= 3 && $m['counters'] > $t['counters']) {
            $notes[] = ['kind' => 'counters_for', 'weight' => 25 + $m['counters'] * 4,
                'text' => sprintf(self::say('مرتداتنا تجد المساحات (%s).', 'Our counters are finding space (%s).'), self::count($m['counters'], self::TIMES))];
        }
        if ($m['offsides'] >= 3) {
            $notes[] = ['kind' => 'offside', 'weight' => 20 + $m['offsides'] * 4,
                'text' => sprintf(self::say('وقعنا في التسلل %s، والتمريرة تخرج متأخرة.', 'We were caught offside %s; the pass is coming too late.'), self::count($m['offsides'], self::TIMES))];
        }
        if ($m['yellow'] >= 2) {
            $notes[] = ['kind' => 'cards', 'weight' => 20 + $m['yellow'] * 6,
                'text' => sprintf(self::say('لدينا %s. تدخل آخر قد يكلفنا لاعباً.', 'We have %s. Another tackle may cost us a player.'), self::count($m['yellow'], self::CARDS))];
        }
        $fits = self::lines($facts['teams'][$side]);
        if ($fits && min($fits) < 72) {
            $line = array_search(min($fits), $fits, true);
            $notes[] = ['kind' => 'fitness', 'weight' => 15 + (72 - min($fits)) * 2,
                'text' => sprintf(self::say('أكثر خطوطنا تعباً: %s بلياقة %d%%.', 'Our most tired line: the %s at %d%% fitness.'), self::line($line), min($fits))];
        }
        if ($m['shots'] >= 3 && $m['shots'] >= $t['shots'] * 2) {
            $notes[] = ['kind' => 'on_top', 'weight' => 20 + $m['shots'],
                'text' => sprintf(self::say('نحن الأخطر: %s مقابل %d.', 'We are the more dangerous side: %s against %d.'), self::count($m['shots'], self::SHOTS), $t['shots'])];
        }

        return $notes;
    }

    /** Average fitness (0 to 100) of each outfield line on the pitch. */
    private static function lines(array $team): array
    {
        $sum = [];
        foreach ($team['players'] as $p) {
            if ($p['on'] && $p['slot_line'] !== 'gk') {
                $sum[$p['slot_line']][] = intdiv($p['fit'], 100);
            }
        }

        return array_map(fn ($v) => intdiv(array_sum($v), count($v)), $sum);
    }
}
