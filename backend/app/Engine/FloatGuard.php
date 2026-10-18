<?php

namespace App\Engine;

use LogicException;

/**
 * PHP silently turns an overflowing integer into a float. The engine is
 * integer-only (CLAUDE.md), so any float in its state is a bug: fail loudly.
 */
final class FloatGuard
{
    public static function check(array $value, string $path = 'state'): void
    {
        foreach ($value as $key => $item) {
            if (is_float($item)) {
                throw new LogicException("Float found in engine $path.$key");
            }
            if (is_array($item)) {
                self::check($item, "$path.$key");
            }
        }
    }
}
