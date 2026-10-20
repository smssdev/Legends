<?php

namespace App\Support;

use Illuminate\Support\Carbon;

/**
 * The game's clock [PLAN 1, GameClock]. Game logic asks this, never now(),
 * so tests (Carbon::setTestNow) and clock:travel can move time.
 *
 * clock:travel stores an offset in seconds in one small file that the web
 * server, the queue worker and the scheduler all read, so every process sees
 * the same game time. Production ignores the file: there the game runs on
 * real time only.
 */
class GameClock
{
    private static ?string $file = null;

    private static ?int $mtime = null;

    private static int $offset = 0;

    public static function now(): Carbon
    {
        return Carbon::now()->addSeconds(self::offset());
    }

    public static function nowMs(): int
    {
        return (int) self::now()->getTimestampMs();
    }

    /** Seconds the game is ahead of real time (behind when negative). */
    public static function offset(): int
    {
        if (app()->isProduction()) {
            return 0;
        }
        $file = self::file();
        clearstatcache(true, $file);
        $mtime = @filemtime($file);
        if ($mtime === false) {
            self::$mtime = null;

            return self::$offset = 0;
        }
        // Long-running workers read the file again only when it changes.
        if ($mtime !== self::$mtime) {
            self::$mtime = $mtime;
            $data = json_decode((string) @file_get_contents($file), true);
            self::$offset = (int) ($data['offset'] ?? 0);
        }

        return self::$offset;
    }

    public static function setOffset(int $seconds): void
    {
        $file = self::file();
        if ($seconds === 0) {
            @unlink($file);
        } else {
            @mkdir(dirname($file), 0775, true);
            file_put_contents($file, json_encode(['offset' => $seconds]), LOCK_EX);
        }
        self::$mtime = null;
        self::$offset = $seconds;
    }

    private static function file(): string
    {
        return self::$file ??= config('game.clock.file', storage_path('app/game-clock.json'));
    }

    /** For tests: point the clock at another file. */
    public static function useFile(?string $file): void
    {
        self::$file = $file;
        self::$mtime = null;
        self::$offset = 0;
    }
}
