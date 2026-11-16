<?php

namespace App\Support;

use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 74 P2] How smoothly the app draws on the players' phones (POST /client-frames), added up: per day, version,
 * tier and screen, the frames drawn and how many came late. Counts only: nothing that names a player or a phone is
 * read or kept (the screen's path loses its ids, as the errors' does). Read in the admin panel beside the devices'
 * errors, kept 30 days. Before it, no figure said whether the app was smooth on a weak phone.
 */
final class ClientFrames
{
    public const PLATFORMS = ['android', 'ios'];

    public const TIERS = ['low', 'mid', 'high'];

    public const KEEP_DAYS = 30;

    /** A session's most frames per screen counted in (an hour at 60 a second, well over any real session's screen). */
    public const MAX_FRAMES = 216000;

    /**
     * Adds one session's screens in.
     *
     * @param  array{platform: string, version: string, tier: string, screens: list<array{path: string, frames: int, late16: int, late33: int}>}  $r
     */
    public static function record(array $r): void
    {
        $day = GameClock::now()->toDateString();
        $version = mb_substr($r['version'], 0, 20);
        $seen = [];
        foreach ($r['screens'] as $s) {
            $path = ClientErrors::path($s['path']);
            $frames = min(self::MAX_FRAMES, max(0, (int) $s['frames']));
            // A screen named twice in one report, or with no frames, counts once or not at all.
            if ($frames === 0 || isset($seen[$path])) {
                continue;
            }
            $seen[$path] = true;
            $late16 = min($frames, max(0, (int) $s['late16']));
            $late33 = min($late16, max(0, (int) $s['late33']));
            $key = ['day' => $day, 'platform' => $r['platform'], 'version' => $version, 'tier' => $r['tier'], 'path' => $path];
            $bump = fn () => DB::table('client_frames')->where($key)->update([
                'frames' => DB::raw('frames + '.$frames), 'late16' => DB::raw('late16 + '.$late16),
                'late33' => DB::raw('late33 + '.$late33), 'sessions' => DB::raw('sessions + 1'),
            ]);
            if ($bump() > 0) {
                continue;
            }
            try {
                DB::table('client_frames')->insert($key + ['frames' => $frames, 'late16' => $late16, 'late33' => $late33, 'sessions' => 1]);
            } catch (UniqueConstraintViolationException) {
                $bump();   // another session's report of the same screen came in between
            }
        }
    }

    /**
     * The panel's table for the last `days` days: per version, tier and screen, its frames and the share drawn late (in
     * hundredths of a percent, whole numbers), the worst screens first; screens with too few frames to judge left out.
     *
     * @return list<array<string, mixed>>
     */
    public static function summary(int $days = 7): array
    {
        return DB::table('client_frames')
            ->where('day', '>=', GameClock::now()->subDays($days)->toDateString())
            ->groupBy('platform', 'version', 'tier', 'path')
            ->selectRaw('platform, version, tier, path, sum(frames) as frames, sum(late16) as late16, sum(late33) as late33, sum(sessions) as sessions')
            ->get()
            ->filter(fn ($r) => (int) $r->frames >= 300)
            ->map(fn ($r) => [
                'platform' => $r->platform,
                'version' => $r->version,
                'tier' => $r->tier,
                'path' => $r->path,
                'frames' => (int) $r->frames,
                'sessions' => (int) $r->sessions,
                'late16_bp' => intdiv((int) $r->late16 * 10000, (int) $r->frames),
                'late33_bp' => intdiv((int) $r->late33 * 10000, (int) $r->frames),
            ])
            ->sortByDesc(fn ($r) => [$r['late33_bp'], $r['frames']])
            ->take(200)->values()->all();
    }

    /** Deletes the days older than KEEP_DAYS. Returns how many rows went. */
    public static function prune(): int
    {
        return DB::table('client_frames')->where('day', '<', GameClock::now()->subDays(self::KEEP_DAYS)->toDateString())->delete();
    }
}
