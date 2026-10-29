<?php

namespace App\Assistant;

/**
 * The smart search [Sprint 22 B2]: the guide's nearest topic to a question, in the coach's own words. Arabic is
 * written many ways, so both sides are brought to one form first: no diacritics or tatweel, one alef, ta marbuta as
 * ha, alef maqsura as ya; "ال" and a joined "و" or "ب" come off; a word one letter off still counts. A pure function
 * of the question and the topics, so it answers when the AI cannot.
 */
class Search
{
    private const STOP = ['ما', 'ماذا', 'هو', 'هي', 'كيف', 'ليش', 'ليه', 'لماذا', 'ازاي', 'يعني', 'ايه', 'في', 'من', 'على', 'عن',
        'هل', 'انا', 'عندي', 'لي', 'الى', 'او', 'و', 'يا', 'شو', 'اي', 'كم', 'متى', 'مين', 'اللي', 'التي', 'الذي', 'ده', 'دي', 'هذا', 'هذه',
        'the', 'a', 'an', 'is', 'are', 'what', 'how', 'do', 'does', 'i', 'my', 'to', 'of', 'in', 'on', 'for', 'and', 'or', 'with',
        'can', 'me', 'it', 'you', 'your', 'when', 'why', 'which', 'who'];

    /** The nearest topic (or null), and up to three others close to the question. */
    public static function find(string $question, array $topics): array
    {
        $words = self::tokens($question);
        if (! $words) {
            return ['topic' => null, 'related' => []];
        }
        $scored = [];
        foreach ($topics as $i => $t) {
            $score = 3 * self::hits($words, self::tokens($t['q'].' '.$t['words'])) + self::hits($words, self::tokens($t['a']));
            if ($score > 0) {
                $scored[] = [$score, $i];
            }
        }
        usort($scored, fn ($a, $b) => [$b[0], $a[1]] <=> [$a[0], $b[1]]);
        $best = $scored && $scored[0][0] >= 3 ? $topics[$scored[0][1]] : null;
        $related = array_map(fn ($s) => $topics[$s[1]], array_slice($scored, $best ? 1 : 0, 3));

        return ['topic' => $best, 'related' => $related];
    }

    /** The words of a text in one written form, without the small ones. */
    public static function tokens(string $text): array
    {
        $s = mb_strtolower($text);
        $s = preg_replace('/[\x{064B}-\x{065F}\x{0670}\x{0640}]/u', '', $s);
        $s = strtr($s, ['أ' => 'ا', 'إ' => 'ا', 'آ' => 'ا', 'ٱ' => 'ا', 'ة' => 'ه', 'ى' => 'ي', 'ؤ' => 'و', 'ئ' => 'ي', 'گ' => 'ك', 'چ' => 'ج', 'ڤ' => 'ف']);
        $s = preg_replace('/[^\p{L}\p{N}]+/u', ' ', $s);
        $out = [];
        foreach (preg_split('/\s+/u', trim($s)) as $w) {
            foreach (['وال', 'بال', 'فال', 'كال', 'لل', 'ال'] as $p) {
                if (mb_strlen($w) > mb_strlen($p) + 2 && str_starts_with($w, $p)) {
                    $w = $p === 'لل' ? mb_substr($w, 2) : mb_substr($w, mb_strlen($p));
                    break;
                }
            }
            if (mb_strlen($w) > 4 && (str_starts_with($w, 'و') || str_starts_with($w, 'ب'))) {
                $w = mb_substr($w, 1);
            }
            if ($w !== '' && ! in_array($w, self::STOP, true) && mb_strlen($w) > 1) {
                $out[$w] = true;
            }
        }

        return array_keys($out);
    }

    /** How many of the question's words the text has: the same word, one starting the other, or one letter off. */
    private static function hits(array $words, array $text): int
    {
        $n = 0;
        foreach ($words as $w) {
            foreach ($text as $x) {
                if ($w === $x || (mb_strlen($w) >= 4 && mb_strlen($x) >= 4 && (str_starts_with($x, $w) || str_starts_with($w, $x)))
                    || (mb_strlen($w) >= 5 && abs(mb_strlen($w) - mb_strlen($x)) <= 1 && self::distance($w, $x) <= 1)) {
                    $n++;
                    break;
                }
            }
        }

        return $n;
    }

    /** The edit distance of two words, letter by letter (not byte by byte). */
    private static function distance(string $a, string $b): int
    {
        $a = mb_str_split($a);
        $b = mb_str_split($b);
        $row = range(0, count($b));
        foreach ($a as $i => $ca) {
            $prev = $row;
            $row = [$i + 1];
            foreach ($b as $j => $cb) {
                $row[$j + 1] = min($prev[$j + 1] + 1, $row[$j] + 1, $prev[$j] + ($ca === $cb ? 0 : 1));
            }
        }

        return $row[count($b)];
    }
}
