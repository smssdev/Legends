<?php

namespace App\Data;

use App\Models\MasterClub;
use Illuminate\Support\Facades\File;

/**
 * [Sprint 58 B2] The clubs' crests as static files (W-P03: every crest was a request through Laravel, 22 on one
 * screen). `php artisan data:crests` (on every start of the web server, and after a club is edited in the data editor)
 * writes each drawn crest to public/crests/{id}-{hash}.svg, the hash from its drawing so a change gets a new name, and
 * a manifest of them (storage/app/crests.json); the web server sends them with a year's cache. A club with a real logo links to the logo itself.
 * Every crest_url in the API comes from here; the old route GET /data/clubs/{id}/crest.svg stays for old links and for a
 * club the manifest does not have yet.
 */
final class Crests
{
    /** @var array<string, string>|null */
    private static ?array $manifest = null;

    public static function dir(): string
    {
        return config('game.crests.dir') ?? public_path('crests');
    }

    /** The manifest (club id → file or logo) beside the app's data, not with the files the browsers cache for a year. */
    public static function manifestPath(): string
    {
        return config('game.crests.manifest') ?? storage_path('app/crests.json');
    }

    /** The crest of a data club (master_clubs.id). */
    public static function url(int|string|null $masterClubId): string
    {
        $id = (int) $masterClubId;
        $file = (self::$manifest ??= self::read())[(string) $id] ?? null;

        return url($file ?? "/api/v1/data/clubs/{$id}/crest.svg");
    }

    /** Writes the crests (all of them, or the clubs given) and the manifest; returns how many files were written. */
    public static function write(?array $ids = null): int
    {
        File::ensureDirectoryExists(self::dir());
        $manifest = $ids === null ? [] : self::read();
        $written = 0;
        $clubs = MasterClub::query()->when($ids !== null, fn ($q) => $q->whereIn('id', $ids))->get(['id', 'name', 'code', 'league_name', 'color_primary', 'color_secondary']);
        foreach ($clubs as $c) {
            foreach (glob(self::dir()."/{$c->id}-*.svg") ?: [] as $old) {
                @unlink($old);
            }
            if (($logo = ClubLogo::path($c->league_name, $c->name)) !== null) {
                $manifest[(string) $c->id] = $logo;

                continue;
            }
            $svg = Crest::svg($c->name, $c->code, $c->color_primary, $c->color_secondary);
            $name = "{$c->id}-".substr(md5($svg), 0, 10).'.svg';
            file_put_contents(self::dir()."/{$name}", $svg);
            $manifest[(string) $c->id] = "/crests/{$name}";
            $written++;
        }
        file_put_contents(self::manifestPath(), json_encode($manifest, JSON_UNESCAPED_SLASHES));
        self::$manifest = $manifest;

        return $written;
    }

    /** @return array<string, string> */
    private static function read(): array
    {
        $path = self::manifestPath();

        return is_file($path) ? (json_decode((string) file_get_contents($path), true) ?: []) : [];
    }

    /** For the tests: read the manifest again. */
    public static function forget(): void
    {
        self::$manifest = null;
    }
}
