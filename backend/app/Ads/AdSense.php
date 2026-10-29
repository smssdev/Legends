<?php

namespace App\Ads;

/**
 * [X57] Google AdSense (the owner's request 2026-10-29: real ads that earn). Everything hangs on the account's
 * publisher id (game.adsense.client, ca-pub- and 16 digits): without a valid one there is no Google script, no
 * ads.txt and no unit, and the game's own ads (HouseAds) stay the only ones.
 */
class AdSense
{
    public static function client(): ?string
    {
        $client = trim((string) config('game.adsense.client'));

        return preg_match('/^ca-pub-\d{10,20}$/', $client) ? $client : null;
    }

    /** What the web reads from /health: the account, the display unit, and whether rewarded videos are tried (and in test). */
    public static function config(): ?array
    {
        $client = self::client();
        if ($client === null) {
            return null;
        }
        $slot = trim((string) config('game.adsense.slot'));

        return ['client' => $client, 'slot' => preg_match('/^\d{6,20}$/', $slot) ? $slot : null,
            'rewarded' => (bool) config('game.adsense.rewarded') && (bool) config('game.ads.enabled'), 'test' => (bool) config('game.adsense.test')];
    }

    /** The line Google asks for in /ads.txt: the account is the site's own seller (Google's fixed certification id). */
    public static function adsTxt(): ?string
    {
        $client = self::client();

        return $client === null ? null : 'google.com, '.substr($client, 3).", DIRECT, f08c47fec0942fa0\n";
    }
}
