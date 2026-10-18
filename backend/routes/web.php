<?php

use Illuminate\Support\Facades\Route;

// The interface is the Vue app in web/. This app only serves the API.
Route::get('/', fn () => ['name' => config('app.name'), 'api' => url('/api/v1')]);
