<?php

namespace App\Analytics;

/**
 * [X81] The site's measurement for the web: Google Analytics 4 (the game's property by default, the owner's 2026-11-02;
 * a measurement id is public by design) and the Meta Pixel (none until META_PIXEL_ID is set on the server). Both load in
 * the browser (web/src/lib/analytics.ts) with Google's Consent Mode: in Europe nothing is stored before the visitor
 * agrees in Google's consent message. An empty setting turns one off.
 */
final class Tracking
{
    /** @return array{ga: string|null, pixel: string|null}|null */
    public static function config(): ?array
    {
        $ga = (string) config('game.analytics.ga');
        $pixel = (string) config('game.analytics.pixel');
        $ga = preg_match('/^G-[A-Z0-9]{4,16}$/', $ga) ? $ga : null;
        $pixel = preg_match('/^\d{8,20}$/', $pixel) ? $pixel : null;

        return $ga || $pixel ? ['ga' => $ga, 'pixel' => $pixel] : null;
    }
}
