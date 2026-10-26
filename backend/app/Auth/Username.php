<?php

namespace App\Auth;

use Illuminate\Support\Facades\DB;

/**
 * The account's username [X4, X11]: 3 to 20 English letters and digits, starting with a letter, kept in lower case
 * and unique. Words that pass for the game's staff (owner, admin, support, mod...) are refused, and the developers'
 * names (Owner-Hamza, Owner-Soliman) are given by the admin only, with the official badge.
 * An account made without one (Google, or before usernames) gets a free one from its email or name.
 */
class Username
{
    public const RULE = 'regex:/^[A-Za-z][A-Za-z0-9]{2,19}$/';

    public static function taken(string $name, ?int $exceptUserId = null): bool
    {
        return DB::table('users')->where('username', strtolower($name))->when($exceptUserId, fn ($q) => $q->where('id', '!=', $exceptUserId))->exists();
    }

    /** The developers' names, in lower case as they are kept. */
    public static function reserved(): array
    {
        return array_map('strtolower', config('game.account.official_usernames'));
    }

    public static function official(?string $name): bool
    {
        return $name !== null && in_array(strtolower($name), self::reserved(), true);
    }

    /** Why a name cannot be had, in Arabic, or null when it is fine (taken or not). */
    public static function refusal(string $name, ?int $exceptUserId = null): ?string
    {
        $lower = strtolower($name);
        foreach (config('game.account.blocked_words') as $word) {
            if (str_contains($lower, $word)) {
                return 'اسم المستخدم فيه كلمة محجوزة لفريق اللعبة، اختر غيره.';
            }
        }
        // The short ones (mod, dev...) alone or with digits only, so a name such as "modric" stays free.
        foreach (config('game.account.blocked_names') as $word) {
            if (preg_match('/^'.preg_quote($word, '/').'\d*$/', $lower)) {
                return 'اسم المستخدم فيه كلمة محجوزة لفريق اللعبة، اختر غيره.';
            }
        }
        if (self::taken($name, $exceptUserId)) {
            return 'اسم المستخدم مأخوذ، اختر غيره.';
        }

        return null;
    }

    /** Up to three free names near the one asked for [X11]. */
    public static function suggestions(string $wanted, int $count = 3): array
    {
        $base = self::base(str_ireplace(config('game.account.blocked_words'), '', $wanted), 14);
        $out = [];
        $coach = str_starts_with($base, 'coach') ? 'the'.$base : 'coach'.$base;
        foreach ([$base.'fc', $base.'10', $coach, $base.'7', $base.'2026', $base.'99', 'the'.$base, $base.'11'] as $candidate) {
            $candidate = substr($candidate, 0, 20);
            if (preg_match('/^[a-z][a-z0-9]{2,19}$/', $candidate) && self::refusal($candidate) === null && ! in_array($candidate, $out, true)) {
                $out[] = $candidate;
            }
            if (count($out) === $count) {
                break;
            }
        }

        return $out;
    }

    /**
     * [UP5] A Google account's username from its name, as the owner's spec asks (Ahmed Ali → ahmedali, or ahmedali7...):
     * the name in English letters (an Arabic one transliterated), and the email's first part when nothing is left.
     */
    public static function fromName(string $name, string $email = ''): string
    {
        $latin = class_exists(\Transliterator::class) ? (string) transliterator_transliterate('Any-Latin; Latin-ASCII; Lower()', $name) : $name;
        $seed = preg_replace('/[^a-z0-9]+/', '', strtolower($latin)) ?: (string) strtok($email, '@');

        return self::free($seed !== '' ? $seed : 'coach');
    }

    /** A free username from any text: its English letters and digits, padded to 3, then a letter suffix until nobody has it. */
    public static function free(string $seed): string
    {
        // Without the staff words, or no suffix would ever free it.
        $base = self::base(str_ireplace(config('game.account.blocked_words'), '', $seed), 16);
        $name = $base;
        for ($n = 0; self::refusal($name) !== null; $n++) {
            $name = $base.self::letters($n);
        }

        return $name;
    }

    /** The letters and digits of a text, from its first letter, at least 3 long. */
    private static function base(string $seed, int $max): string
    {
        $base = ltrim(strtolower((string) preg_replace('/[^A-Za-z0-9]+/', '', $seed)), '0123456789');

        // Nothing left (a name of staff words alone, or not in English letters): "coach".
        return $base === '' ? 'coach' : str_pad(substr($base, 0, $max), 3, 'x');
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
