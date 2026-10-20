<?php

use App\Http\Controllers\AccountLinkController;
use Illuminate\Support\Facades\Route;

// The interface is the Vue app in web/. In development Vite serves it; in a
// packaged build (composer build-web) its files sit in public/ and every
// non-API path falls back to its index.html so the Vue router can take over.
$spa = function () {
    $index = public_path('index.html');

    return is_file($index)
        ? response()->file($index, ['Content-Type' => 'text/html; charset=UTF-8'])
        : response()->json(['name' => config('app.name'), 'api' => url('/api/v1')]);
};

// Links that open in the browser: the email confirmation, and Google's sign-in on the web [PLAN 2.17].
Route::get('/email/verify/{id}/{hash}', [AccountLinkController::class, 'verify'])
    ->middleware(['signed', 'throttle:12,1'])->whereNumber('id')->name('verification.verify');
Route::get('/auth/google/redirect', [AccountLinkController::class, 'googleRedirect'])->middleware('throttle:20,1');
Route::get('/auth/google/callback', [AccountLinkController::class, 'googleCallback'])->middleware('throttle:20,1');

Route::get('/', $spa);
Route::fallback(function () use ($spa) {
    abort_if(request()->is('api/*'), 404);

    return $spa();
});
