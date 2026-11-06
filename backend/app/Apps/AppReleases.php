<?php

namespace App\Apps;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 15 D1, the owner's request 2026-11-06] The app to download from the site. The admin uploads the Android APK
 * in small pieces (each well under any upload limit of PHP or the server's nginx), in order; once whole, its size and
 * its first bytes (an APK is a zip) are checked, it is fingerprinted (sha256) and becomes the latest. The two latest
 * ready files are kept, older ones deleted. The files live on the server's downloads volume (deploy/vps/compose.yml).
 */
class AppReleases
{
    public const PLATFORMS = ['android'];

    public static function dir(): string
    {
        return (string) config('game.app.downloads_dir');
    }

    public static function path(int $id): string
    {
        return self::dir()."/release-{$id}.apk";
    }

    public static function start(string $version, int $bytes, ?string $notes, ?int $userId): int
    {
        $max = (int) config('game.app.max_mb') * 1024 * 1024;
        if ($bytes < 1024 || $bytes > $max) {
            throw new HttpException(422, sprintf('حجم الملف بين 1 كيلوبايت و%d ميجابايت.', config('game.app.max_mb')));
        }
        if (! is_dir(self::dir()) && ! @mkdir(self::dir(), 0775, true) && ! is_dir(self::dir())) {
            throw new HttpException(500, 'مجلد التنزيلات غير متاح على الخادم.');
        }
        $now = GameClock::now();
        $id = DB::table('app_releases')->insertGetId(['platform' => 'android', 'version' => $version, 'notes' => $notes, 'bytes' => $bytes,
            'user_id' => $userId, 'created_at' => $now, 'updated_at' => $now]);
        file_put_contents(self::path($id), '');

        return $id;
    }

    /** One piece at its offset: the next one only, so a piece sent twice is never added twice. Returns the bytes received. */
    public static function chunk(int $id, int $offset, string $bytes): int
    {
        $r = DB::table('app_releases')->where('id', $id)->first();
        if (! $r || $r->status !== 'uploading') {
            throw new HttpException(404, 'لا رفع جارٍ بهذا الرقم.');
        }
        if ($offset !== (int) $r->received) {
            // Already have it (a retry): say where to go on from.
            if ($offset < (int) $r->received) {
                return (int) $r->received;
            }
            throw new HttpException(409, 'قطعة خارج الترتيب.');
        }
        if ($offset + strlen($bytes) > (int) $r->bytes) {
            throw new HttpException(422, 'القطعة أكبر من الملف المعلن.');
        }
        file_put_contents(self::path($id), $bytes, FILE_APPEND | LOCK_EX);
        $received = $offset + strlen($bytes);
        DB::table('app_releases')->where('id', $id)->where('received', $offset)->update(['received' => $received, 'updated_at' => GameClock::now()]);

        return $received;
    }

    /** The upload is whole: checked, fingerprinted, published as the latest; older files beyond the two latest go. */
    public static function finish(int $id): array
    {
        $r = DB::table('app_releases')->where('id', $id)->where('status', 'uploading')->first();
        if (! $r) {
            throw new HttpException(404, 'لا رفع جارٍ بهذا الرقم.');
        }
        $path = self::path($id);
        clearstatcache(true, $path);
        if ((int) $r->received !== (int) $r->bytes || ! is_file($path) || filesize($path) !== (int) $r->bytes) {
            throw new HttpException(409, 'لم يكتمل الملف بعد.');
        }
        $head = (string) file_get_contents($path, false, null, 0, 4);
        if ($head !== "PK\x03\x04") {
            @unlink($path);
            DB::table('app_releases')->where('id', $id)->delete();
            throw new HttpException(422, 'الملف ليس تطبيق أندرويد (APK).');
        }
        $now = GameClock::now();
        DB::table('app_releases')->where('id', $id)->update(['status' => 'ready', 'sha256' => hash_file('sha256', $path), 'published_at' => $now, 'updated_at' => $now]);
        foreach (DB::table('app_releases')->where('platform', $r->platform)->where('status', 'ready')->orderByDesc('id')->skip(2)->take(100)->pluck('id') as $old) {
            @unlink(self::path((int) $old));
            DB::table('app_releases')->where('id', $old)->update(['status' => 'removed', 'updated_at' => $now]);
        }

        return self::card(DB::table('app_releases')->where('id', $id)->first());
    }

    public static function delete(int $id): void
    {
        @unlink(self::path($id));
        DB::table('app_releases')->where('id', $id)->update(['status' => 'removed', 'updated_at' => GameClock::now()]);
    }

    /** The latest ready release of a platform, or null. */
    public static function latest(string $platform = 'android'): ?object
    {
        return DB::table('app_releases')->where('platform', $platform)->where('status', 'ready')->orderByDesc('id')->first();
    }

    public static function card(object $r): array
    {
        return ['id' => (int) $r->id, 'platform' => $r->platform, 'version' => $r->version, 'notes' => $r->notes, 'bytes' => (int) $r->bytes,
            'received' => (int) $r->received, 'status' => $r->status, 'sha256' => $r->sha256, 'downloads' => (int) $r->downloads,
            'published_at' => $r->published_at ? Carbon::parse($r->published_at, 'UTC')->toIso8601ZuluString() : null,
            'url' => $r->status === 'ready' ? url('/api/v1/app/android.apk') : null];
    }
}
