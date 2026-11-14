<?php

use App\Ads\AdSense;
use App\Http\Controllers\AccountLinkController;
use App\Http\Controllers\InviteController;
use Illuminate\Support\Facades\Route;

// The interface is the Vue app in web/. In development Vite serves it; in a
// packaged build (composer build-web) its files sit in public/ and every
// non-API path falls back to its index.html so the Vue router can take over.
$spa = function () {
    // [SEO] A public page built with its own tags (web/scripts/seo.mjs) goes out as itself.
    $own = public_path(trim(request()->path(), '/').'/index.html');
    $index = request()->path() !== '/' && ! str_contains(request()->path(), '..') && is_file($own) ? $own : public_path('index.html');

    return is_file($index)
        ? response()->file($index, ['Content-Type' => 'text/html; charset=UTF-8'])
        : response()->json(['name' => config('app.name'), 'api' => url('/api/v1')]);
};

// Links that open in the browser: the email confirmation, and Google's sign-in on the web [PLAN 2.17].
Route::get('/email/verify/{id}/{hash}', [AccountLinkController::class, 'verify'])
    ->middleware(['signed', 'throttle:12,1'])->whereNumber('id')->name('verification.verify');
Route::get('/auth/google/redirect', [AccountLinkController::class, 'googleRedirect'])->middleware('throttle:20,1');
Route::get('/auth/google/callback', [AccountLinkController::class, 'googleCallback'])->middleware('throttle:20,1');

// The invite link shared on WhatsApp: the app, with the league's card for the link preview [Sprint 14 B2].
Route::get('/join/{code}', [InviteController::class, 'show'])->middleware('throttle:60,1')->where('code', '[A-Za-z0-9#-]{1,16}');

// [X57] Google's ads.txt: the AdSense account that sells this site's ads, once it is set on the server.
Route::get('/ads.txt', function () {
    $line = AdSense::adsTxt();
    abort_if($line === null, 404);

    return response($line, 200, ['Content-Type' => 'text/plain; charset=UTF-8', 'Cache-Control' => 'public, max-age=3600']);
});

// [Sprint 62 B1] Android's App Links: the app may open this site's invitation links (/join/, /groups/join/), signed by
// the release key whose fingerprint the server knows. The iPhone installs the web app (README section 0), so no Apple file.
Route::get('/.well-known/assetlinks.json', function () {
    $prints = array_values(array_filter(array_map('trim', explode(',', (string) config('game.app.android_cert_sha256')))));
    abort_if($prints === [], 404);

    return response()->json([[
        'relation' => ['delegate_permission/common.handle_all_urls'],
        'target' => ['namespace' => 'android_app', 'package_name' => config('game.app.android_package'), 'sha256_cert_fingerprints' => $prints],
    ]], 200, ['Cache-Control' => 'public, max-age=3600']);
});

Route::get('/', $spa);
Route::fallback(function () use ($spa) {
    abort_if(request()->is('api/*'), 404);

    return $spa();
});
