<?php

namespace App\Ads;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * The game's own rewarded ads [Sprint 20 S4, the owner's decision 2026-10-29: "make a free ad provider yourself"]: no
 * outside network, no account, no SDK. The ads are the developers' own (written in the admin panel) or, when none is
 * active, the game's built-in ones (game.ads.house_defaults: tips and features). Watching starts a timed session on
 * the server; the reward's token is that session, and it counts only once the ad's seconds have passed (the verifier
 * below), once. So an ad cannot be skipped by a script, only waited out.
 */
class HouseAds implements RewardVerifier
{
    public function name(): string
    {
        return 'house';
    }

    /**
     * A new watch for this account: the ad to show and the token that will claim the reward. [X57] For Google's rewarded
     * video (adsense) there is no ad of ours to show: Google plays its own, and the watch only times it on the server.
     */
    public static function start(int $userId, string $locale, string $provider = 'house'): array
    {
        $now = GameClock::now();
        // A few at a time: a token is a short wait, not a stock to hoard.
        abort_if(DB::table('ad_watches')->where('user_id', $userId)->whereNull('used_at')->where('started_at', '>', $now->copy()->subMinutes(10))->count() >= 5,
            429, 'شاهد الإعلان المفتوح أولاً.');
        $ad = null;
        if ($provider === 'adsense') {
            $shown = null;
            $seconds = (int) config('game.adsense.adsense_seconds');
        } else {
            $ads = DB::table('house_ads')->where('active', true)->get();
            $ad = $ads->isNotEmpty() ? $ads[random_int(0, $ads->count() - 1)] : null;
            $shown = $ad
                ? ['id' => $ad->id, 'title' => $ad->title, 'body' => $ad->body, 'cta_label' => $ad->cta_label, 'cta_url' => $ad->cta_url, 'seconds' => (int) $ad->seconds]
                : self::builtIn($locale);
            $seconds = $shown['seconds'];
        }
        $token = Str::random(48);
        DB::table('ad_watches')->insert(['token' => $token, 'user_id' => $userId, 'house_ad_id' => $ad?->id, 'seconds' => $seconds, 'started_at' => $now, 'provider' => $provider]);
        if ($ad) {
            DB::table('house_ads')->where('id', $ad->id)->increment('views');
        }

        return ['token' => $token, 'ad' => $shown, 'ends_at' => $now->copy()->addSeconds($seconds)->toIso8601ZuluString()];
    }

    /** One of the game's own ads, in the account's language. */
    private static function builtIn(string $locale): array
    {
        $all = config('game.ads.house_defaults');
        $one = $all[random_int(0, count($all) - 1)];

        return ['id' => null, 'title' => $one[$locale === 'en' ? 'title_en' : 'title'], 'body' => $one[$locale === 'en' ? 'body_en' : 'body'],
            'cta_label' => null, 'cta_url' => null, 'seconds' => (int) config('game.ads.house_seconds')];
    }

    /**
     * The token of an ad this account watched to its end: its watch's id is the reward's id. The same token again (a
     * retry) gives the same id, and AdReward keeps reward ids unique, so it never pays twice.
     */
    public function verify(string $token, int $userId): ?string
    {
        $w = DB::table('ad_watches')->where('token', $token)->where('user_id', $userId)->first();
        if (! $w || Carbon::parse($w->started_at, 'UTC')->addSeconds((int) $w->seconds)->gt(GameClock::now())) {
            return null;
        }
        DB::table('ad_watches')->where('id', $w->id)->whereNull('used_at')->update(['used_at' => GameClock::now()]);

        return 'watch:'.$w->id;
    }
}
