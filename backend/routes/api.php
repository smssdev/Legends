<?php

use App\Http\Controllers\Api\SimulatorController;
use Illuminate\Support\Facades\Route;

// Every route here is served under /api/v1 (see bootstrap/app.php) and is
// documented in docs/api/openapi.yaml in the same PR.

// Simulator: development (and admin, later) only. See docs/MATCH_VIEW.md 8.
Route::prefix('sim')->middleware('simulator')->controller(SimulatorController::class)->group(function () {
    Route::get('leagues', 'leagues');
    Route::get('clubs', 'clubs');
    Route::get('clubs/{club}', 'club');
    Route::post('matches', 'store');
    Route::get('matches/{match}', 'show');
    Route::post('matches/{match}/actions', 'order')->middleware('throttle:120,1');
    Route::post('matches/{match}/ticks', 'ticks');
    Route::post('matches/{match}/start', 'start');
    Route::get('matches/{match}/live', 'live')->middleware('throttle:240,1');
    Route::get('matches/{match}/report', 'report');
});
