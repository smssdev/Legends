<?php

namespace App\Support;

/**
 * [X61] One spelling per country: the Arab data wrote them in capitals (EGYPT, IRAQ, MOROCCO) and the EA data does not
 * (Egypt), so the scout listed both and chemistry saw two nations. A name all in capitals reads as a title here; the
 * stored data (read-only master tables) is not changed.
 */
class Nation
{
    public static function name(?string $nation): ?string
    {
        if ($nation === null || $nation === '') {
            return $nation;
        }
        if (preg_match('/\p{Ll}/u', $nation) === 1) {
            return $nation;
        }

        return mb_convert_case(mb_strtolower($nation), MB_CASE_TITLE);
    }

    /** The key two spellings of one country share. */
    public static function key(?string $nation): string
    {
        return mb_strtolower(trim((string) $nation));
    }
}
