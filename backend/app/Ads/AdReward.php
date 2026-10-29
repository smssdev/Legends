<?php

namespace App\Ads;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Rewarded videos cut a task's time [Sprint 21 E9, the owner's decision 2026-10-28]: each video the provider verifies
 * takes game.ads.minutes_per_video off a training slot's next session or a stadium part's build, up to
 * game.ads.max_per_item videos for the same task. The provider's reward id is kept unique, so a token sent twice
 * (a retry, a double tap) cuts once. Off until the owner picks the provider (game.ads.enabled, game.ads.driver).
 */
class AdReward
{
    public const ITEMS = ['training', 'stadium'];

    /** @return array{minutes: int, used: int, max: int, ends_at: string} */
    public static function apply(RewardVerifier $verifier, int $userId, int $clubId, string $item, ?string $line, string $token): array
    {
        if (! config('game.ads.enabled')) {
            throw new HttpException(503, 'الإعلانات غير مفعّلة بعد.');
        }
        [$table, $id, $column] = self::task($clubId, $item, $line);
        $reward = $verifier->verify($token, $userId);
        if ($reward === null) {
            throw new HttpException(422, 'لم يتأكد مزوّد الإعلانات من مشاهدة الفيديو كاملاً.');
        }
        $minutes = (int) config('game.ads.minutes_per_video');
        $max = (int) config('game.ads.max_per_item');

        return DB::transaction(function () use ($verifier, $userId, $clubId, $item, $table, $id, $column, $reward, $minutes, $max) {
            $used = DB::table('ad_rewards')->where('item', $item)->where('item_id', $id)->count();
            $seen = DB::table('ad_rewards')->where('provider', $verifier->name())->where('reward_id', $reward)->exists();
            if (! $seen) {
                if ($used >= $max) {
                    throw new HttpException(409, sprintf(__('وصلت إلى %d فيديوهات لهذه المهمة.'), $max));
                }
                $now = GameClock::now();
                DB::table('ad_rewards')->insert(['user_id' => $userId, 'club_id' => $clubId, 'item' => $item, 'item_id' => $id, 'provider' => $verifier->name(),
                    'reward_id' => $reward, 'minutes' => $minutes, 'created_at' => $now]);
                // Never before now: a task cut past its end is simply due, and the scheduler finishes it within the minute.
                $at = Carbon::parse(DB::table($table)->where('id', $id)->value($column), 'UTC')->subMinutes($minutes);
                DB::table($table)->where('id', $id)->update([$column => $at->lt($now) ? $now : $at, 'updated_at' => $now]);
                $used++;
            }

            return ['minutes' => $minutes, 'used' => $used, 'max' => $max,
                'ends_at' => Carbon::parse(DB::table($table)->where('id', $id)->value($column), 'UTC')->toIso8601ZuluString()];
        });
    }

    /** The club's task the video is for: [table, id, the time column it cuts]. */
    private static function task(int $clubId, string $item, ?string $line): array
    {
        $id = $item === 'training'
            ? DB::table('training_slots')->where('club_id', $clubId)->where('line', $line)->value('id')
            : DB::table('stadium_builds')->where('club_id', $clubId)->where('status', 'building')->value('id');
        if (! $id) {
            throw new HttpException(404, $item === 'training' ? 'لا لاعب في هذه الخانة.' : 'لا جزء يُبنى الآن.');
        }

        return $item === 'training' ? ['training_slots', (int) $id, 'next_at'] : ['stadium_builds', (int) $id, 'ends_at'];
    }
}
