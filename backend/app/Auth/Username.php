<?php

namespace App\Auth;

use Illuminate\Support\Facades\DB;

/**
 * The account's username [X4, 2026-10-24]: 3 to 20 English letters, nothing else, kept in lower case and unique.
 * An account made without one (Google, or before usernames) gets a free one from its email or name.
 */
class Username
{
    public const RULE = 'regex:/^[A-Za-z]{3,20}$/';

    public static function taken(string $name, ?int $exceptUserId = null): bool
    {
        return DB::table('users')->where('username', strtolower($name))->when($exceptUserId, fn ($q) => $q->where('id', '!=', $exceptUserId))->exists();
    }

    /** A free username from any text: its English letters, padded to 3, then a letter suffix until nobody has it. */
    public static function free(string $seed): string
    {
        $base = substr(strtolower(preg_replace('/[^A-Za-z]+/', '', $seed)), 0, 16);
        $base = str_pad($base, 3, 'x');
        $name = $base;
        for ($n = 0; self::taken($name); $n++) {
            $name = $base.self::letters($n);
        }

        return $name;
    }

    /** 0 → a, 25 → z, 26 → aa, ...: a suffix of letters only. */
    private static function letters(int $n): string
    {
        $s = '';
        do {
            $s = chr(97 + $n % 26).$s;
            $n = intdiv($n, 26) - 1;
        } while ($n >= 0);

        return $s;
    }
}
