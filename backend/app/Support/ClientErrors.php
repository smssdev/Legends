<?php

namespace App\Support;

use Carbon\Carbon;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 66 B1] The errors the players' devices report (POST /client-errors), gathered by what they are: the same error
 * in the same version counts up on one row instead of filling a table. Nothing that names a player is kept: no account,
 * no address, and the text is scrubbed (an email, a long number, an id in the path). Read in the admin panel, kept 30
 * days after the last time it came.
 */
final class ClientErrors
{
    public const PLATFORMS = ['web', 'android', 'ios'];

    public const KEEP_DAYS = 30;

    /** The text without what could name someone: emails, long numbers (a phone, a code), tokens. */
    public static function scrub(string $text): string
    {
        $text = preg_replace('/[^\s@]+@[^\s@]+\.[^\s@]+/u', '[email]', $text) ?? '';
        $text = preg_replace('/\b[A-Za-z0-9_\-]{32,}\b/', '[token]', $text) ?? '';

        return preg_replace('/\d{4,}/', '#', $text) ?? '';
    }

    /** A screen's path without its query, its fragment or its ids: /leagues/12/match/7?x → /leagues/{n}/match/{n}. */
    public static function path(string $path): string
    {
        $path = strtok($path, '?#') ?: '/';

        return mb_substr(preg_replace('#/\d+(?=/|$)#', '/{n}', $path) ?? '/', 0, 200);
    }

    /**
     * Counts one error in. `$e` holds platform, version, path, message and stack (already validated).
     *
     * @param  array{platform: string, version: string, path?: string|null, message: string, stack?: string|null}  $e
     */
    public static function record(array $e): void
    {
        $message = mb_substr(self::scrub(trim($e['message'])), 0, 300);
        $stack = implode("\n", array_slice(preg_split('/\R/', self::scrub((string) ($e['stack'] ?? ''))) ?: [], 0, 8));
        $stack = mb_substr($stack, 0, 1500);
        $version = mb_substr($e['version'], 0, 20);
        $first = strtok($stack, "\n") ?: '';
        $fingerprint = sha1($e['platform']."\n".$version."\n".$message."\n".$first);
        $now = GameClock::now();

        $bump = fn () => DB::table('client_errors')->where('fingerprint', $fingerprint)
            ->update(['count' => DB::raw('count + 1'), 'last_seen_at' => $now, 'path' => self::path((string) ($e['path'] ?? '/'))]);
        if ($bump() > 0) {
            return;
        }
        try {
            DB::table('client_errors')->insert([
                'fingerprint' => $fingerprint,
                'platform' => $e['platform'],
                'version' => $version,
                'path' => self::path((string) ($e['path'] ?? '/')),
                'message' => $message,
                'stack' => $stack,
                'count' => 1,
                'first_seen_at' => $now,
                'last_seen_at' => $now,
            ]);
        } catch (UniqueConstraintViolationException) {
            $bump();   // another report of the same error came in between
        }
    }

    /**
     * The panel's list: the errors seen in the last `days` days, the most recent first.
     *
     * @return list<array<string, mixed>>
     */
    public static function recent(int $days = 7, ?string $platform = null): array
    {
        return DB::table('client_errors')
            ->where('last_seen_at', '>=', GameClock::now()->subDays($days))
            ->when($platform, fn ($q) => $q->where('platform', $platform))
            ->orderByDesc('last_seen_at')->limit(200)->get()
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'platform' => $r->platform,
                'version' => $r->version,
                'path' => $r->path,
                'message' => $r->message,
                'stack' => $r->stack,
                'count' => (int) $r->count,
                'first_seen_at' => Carbon::parse($r->first_seen_at, 'UTC')->toIso8601ZuluString(),
                'last_seen_at' => Carbon::parse($r->last_seen_at, 'UTC')->toIso8601ZuluString(),
            ])->all();
    }

    /** Deletes what was not seen for KEEP_DAYS days. */
    public static function prune(): int
    {
        return DB::table('client_errors')->where('last_seen_at', '<', GameClock::now()->subDays(self::KEEP_DAYS))->delete();
    }
}
