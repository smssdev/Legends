<?php

namespace App\Data;

use Illuminate\Support\Facades\Cache;

/**
 * A club's real logo [UP3, owner's decision 2026-10-26]: data/names/club_logos.csv (tools/data/club_logos.py)
 * links each club of the data, by its league and name, to a picture the site serves under /logos. A club
 * without one keeps its drawn badge (Crest).
 */
class ClubLogo
{
    /** The logo's path on the site ("/logos/england/arsenal.webp"), or null. Without the league, by the name alone. */
    public static function path(?string $league, string $club): ?string
    {
        $image = $league !== null ? (self::map()[$league."\t".$club] ?? null) : (self::map()["\t".$club] ?? null);

        return $image ? '/logos/'.$image : null;
    }

    /** A match's club (its state's `club`) with its logo added, for the screens only (never the engine). */
    public static function with(array $club): array
    {
        return $club + ['logo' => self::path($club['league'] ?? null, (string) ($club['name'] ?? ''))];
    }

    /** @return array<string, string> "league\tclub" => image */
    private static function map(): array
    {
        static $map = null;

        return $map ??= Cache::rememberForever('club_logos:'.self::version(), function (): array {
            $file = self::file();
            if (! is_file($file)) {
                return [];
            }
            $map = [];
            $fh = fopen($file, 'r');
            fgetcsv($fh, escape: '\\');
            while (($row = fgetcsv($fh, escape: '\\')) !== false) {
                if (count($row) >= 5 && $row[4] !== '') {
                    $map[$row[0]."\t".$row[1]] = $row[4];
                    $map["\t".$row[1]] ??= $row[4];
                }
            }
            fclose($fh);

            return $map;
        });
    }

    private static function file(): string
    {
        return base_path('../data/names/club_logos.csv');
    }

    private static function version(): string
    {
        return is_file(self::file()) ? (string) filemtime(self::file()) : '0';
    }
}
