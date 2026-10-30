<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/**
 * [X61] A name or title anyone will see is not a test's: "test", "تست", "asdf", one key held down ("hhhh")... are
 * refused, so a trial league or announcement never reaches the players again. A real name with such a word in it
 * ("Test Cup 2026") passes.
 */
class NotJunk implements ValidationRule
{
    private const WORDS = ['test', 'tests', 'tesst', 'testt', 'tst', 'تست', 'تيست', 'تجربة', 'تجربه', 'اختبار', 'asdf', 'qwerty', 'qwe', 'abc', 'xxx', 'aaa', 'ytkregekgek'];

    public static function junk(string $value): bool
    {
        $v = mb_strtolower(trim(preg_replace('/[\s\p{P}\d]+/u', ' ', $value)));
        $v = trim(preg_replace('/\s+/u', ' ', $v));

        return $v !== '' && (in_array($v, self::WORDS, true) || preg_match('/^(\X)\1{2,}$/u', str_replace(' ', '', $v)) === 1);
    }

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (is_string($value) && self::junk($value)) {
            $fail(__('اختر اسماً حقيقياً، لا اسم تجربة.'));
        }
    }
}
