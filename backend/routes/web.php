<?php

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

Route::get('/', $spa);
Route::fallback(function () use ($spa) {
    abort_if(request()->is('api/*'), 404);

    return $spa();
});
